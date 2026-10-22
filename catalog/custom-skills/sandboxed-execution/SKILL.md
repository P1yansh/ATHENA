---
name: sandboxed-execution
description: Architecture, security constraints, and patterns for safe, isolated execution of untrusted user code using Docker, resource limits, ephemeral containers, and real-time stdout/stderr streaming over WebSockets. Use when designing, building, or auditing code runner environments.
metadata:
  origin: Athena
---

# Secure Sandboxed Code Execution

Architecture and implementation guidelines for executing arbitrary user-submitted code in an isolated environment with strict resource limits, security defenses, and real-time output broadcast.

## When to Activate

- Designing the code execution pipeline for languages like Node.js, Python, TypeScript, C++, Rust, etc.
- Implementing container lifecycle management with Dockerode or Docker CLI.
- Configuring security defenses: unprivileged execution, dropped capabilities, read-only root filesystems, network isolation.
- Enforcing resource constraints: memory caps, CPU quotas, process count (PID) limits, execution timeouts.
- Streaming stdout and stderr output in real time to authorized project collaborators via WebSockets.

---

## 1. Security Threat Model & Defense In Depth

Executing untrusted code on a multi-tenant platform exposes high-risk attack vectors:
1. **Host Compromise & Privilege Escalation**: Attackers running as `root` attempting container escape.
2. **Denial of Service (DoS)**: Fork bombs (`:(){ :|:& };:`), infinite loops, memory exhaustion.
3. **Network Infiltration / SSRF**: Accessing internal microservices, metadata endpoints (`169.254.169.254`), or scanning local network.
4. **Host Filesystem Tampering**: Modifying host binaries, persisting malicious files or malware.

### The 7 Golden Rules of Sandboxing
| Defense Layer | Enforcement Mechanism |
|---|---|
| **User Privileges** | Run as unprivileged user (`USER nobody` / `uid=1001`, `gid=1001`). Never root. |
| **Linux Capabilities** | Drop all Linux capabilities: `--cap-drop=ALL` (or restrict to absolute bare minimum). |
| **Filesystem Safety** | Mount root filesystem as read-only: `--read-only`. Provide small ephemeral in-memory `/tmp` tmpfs. |
| **Network Isolation** | Disable network access during execution: `--network=none` (or restrict via strict firewall egress rules). |
| **Process Limits** | Guard against fork bombs: `--pids-limit=64`. |
| **Resource Caps** | Enforce hard CPU and RAM limits: `--memory="256m" --cpus="0.5"`. |
| **Execution Timeout** | Hard timeout kill switch (e.g., 5 to 10 seconds max) terminating container with `SIGKILL`. |

---

## 2. Docker Runner Configuration & Dockerfile

### Base Runner Container (`runner.Dockerfile`)
```dockerfile
FROM alpine:3.19

# Install required execution runtimes
RUN apk add --no-cache nodejs python3 py3-pip gcc g++

# Create non-root runner user
RUN adduser -D -u 10001 runner

USER runner
WORKDIR /home/runner

CMD ["sh"]
```

---

## 3. Node.js Dockerode Execution Engine

```typescript
import Docker from 'dockerode';
import { PassThrough } from 'stream';

const docker = new Docker({ socketPath: '/var/run/docker.sock' });

export interface ExecutionRequest {
  code: string;
  language: 'javascript' | 'python' | 'typescript';
  timeoutMs?: number;
}

export interface ExecutionResult {
  stdout: string;
  stderr: string;
  exitCode: number;
  durationMs: number;
  timedOut: boolean;
}

export async function executeCodeInSandbox(
  req: ExecutionRequest,
  onOutputChunk?: (stream: 'stdout' | 'stderr', chunk: string) => void
): Promise<ExecutionResult> {
  const timeoutMs = req.timeoutMs || 5000;
  const startTime = Date.now();

  const command = getExecutionCommand(req.language, req.code);

  // 1. Create Container with Hardened Constraints
  const container = await docker.createContainer({
    Image: 'devcollab-runner:latest',
    Cmd: ['sh', '-c', command],
    AttachStdout: true,
    AttachStderr: true,
    Tty: false,
    HostConfig: {
      Memory: 256 * 1024 * 1024, // 256 MB RAM limit
      MemorySwap: 256 * 1024 * 1024, // Disable swap expansion
      NanoCpus: 500_000_000, // 0.5 CPU cores
      NetworkMode: 'none', // No internet / network access
      ReadonlyRootfs: true, // Read-only root
      CapDrop: ['ALL'], // Drop all Linux capabilities
      SecurityOpt: ['no-new-privileges'], // Prevent setuid escalation
      PidsLimit: 64, // Prevent fork bombs
      Tmpfs: {
        '/tmp': 'rw,noexec,nosuid,size=32m', // Isolated ephemeral RAM temp
      },
    },
    User: '10001:10001',
  });

  let timedOut = false;
  let stdoutData = '';
  let stderrData = '';

  // 2. Attach output stream for real-time streaming
  const stream = await container.attach({
    stream: true,
    stdout: true,
    stderr: true,
  });

  const stdoutStream = new PassThrough();
  const stderrStream = new PassThrough();
  docker.modem.demuxStream(stream, stdoutStream, stderrStream);

  stdoutStream.on('data', (chunk) => {
    const text = chunk.toString();
    stdoutData += text;
    onOutputChunk?.('stdout', text);
  });

  stderrStream.on('data', (chunk) => {
    const text = chunk.toString();
    stderrData += text;
    onOutputChunk?.('stderr', text);
  });

  // 3. Start Container
  await container.start();

  // 4. Hard Timeout Guard
  const timer = setTimeout(async () => {
    timedOut = true;
    try {
      await container.kill({ signal: 'SIGKILL' });
    } catch (e) {
      // Container may have already exited
    }
  }, timeoutMs);

  // 5. Wait for finish
  try {
    const waitResult = await container.wait();
    clearTimeout(timer);

    return {
      stdout: stdoutData,
      stderr: stderrData,
      exitCode: timedOut ? 124 : waitResult.StatusCode,
      durationMs: Date.now() - startTime,
      timedOut,
    };
  } finally {
    clearTimeout(timer);
    try {
      await container.remove({ force: true });
    } catch (e) {
      // Container cleanup
    }
  }
}

function getExecutionCommand(lang: string, code: string): string {
  // Pass code via echo or base64 decode to avoid shell escaping pitfalls
  const encoded = Buffer.from(code).toString('base64');
  switch (lang) {
    case 'javascript':
      return `echo "${encoded}" | base64 -d | node -`;
    case 'python':
      return `echo "${encoded}" | base64 -d | python3 -`;
    default:
      throw new Error(`Unsupported sandbox language: ${lang}`);
  }
}
```

---

## 4. Real-Time Output Broadcasting via Socket.IO

When code executes, output must be multiplexed and broadcast to all connected project collaborators:

```typescript
// Server-side Socket.IO handler
socket.on('run_code', async ({ projectId, filePath, code, language }) => {
  // 1. RBAC Check: Ensure user has 'editor' or 'owner' role
  const canExecute = await checkUserPermission(socket.data.userId, projectId, 'execute');
  if (!canExecute) {
    return socket.emit('execution_error', { message: 'Unauthorized to execute code in this project' });
  }

  // 2. Broadcast execution start to room
  io.to(`project:${projectId}`).emit('execution_started', {
    startedBy: socket.data.user.name,
    filePath,
    timestamp: new Date().toISOString(),
  });

  // 3. Run with streaming callback
  const result = await executeCodeInSandbox({ code, language }, (type, chunk) => {
    io.to(`project:${projectId}`).emit('execution_output_chunk', {
      type, // 'stdout' | 'stderr'
      chunk,
    });
  });

  // 4. Broadcast execution complete
  io.to(`project:${projectId}`).emit('execution_completed', result);
});
```

---

## Security Verification Checklist
- [ ] Container runs with `--network=none`.
- [ ] Non-root execution verified (`whoami` returns `runner` / `uid 10001`).
- [ ] Memory limit enforced (container killed if memory exceeds cap, no swap overflow).
- [ ] Fork bomb cannot exhaust host process table (`--pids-limit` active).
- [ ] Readonly rootfs prevents writes to `/bin`, `/usr`, `/etc`.
- [ ] Ephemeral containers are forcefully removed (`container.remove({ force: true })`) in `finally` block.
- [ ] Output buffer truncated at max bytes (e.g. 500KB) to prevent client memory crashes.
