---
name: crdt-collaboration
description: Architecture, patterns, and best practices for real-time collaborative editing using CRDTs (Conflict-free Replicated Data Types) with Yjs, Monaco Editor, live cursors, awareness protocol, and recoverable version snapshots. Use when designing, implementing, or debugging real-time multi-user editing and synchronization.
metadata:
  origin: Athena
---

# CRDT & Real-Time Collaboration Patterns

Production patterns and architectural guidelines for real-time collaborative text editing, multi-cursor synchronization, awareness presence, and version history using Yjs and Monaco Editor.

## When to Activate

- Designing or implementing real-time collaborative editing using Yjs or Automerge.
- Binding Monaco Editor to Yjs shared text types (`y-monaco`).
- Managing multi-user cursor tracking, selection ranges, and user presence styling.
- Handling WebSocket sync protocols (`y-websocket`) and connection lifecycle.
- Managing user-scoped Undo/Redo (`Y.UndoManager`) without stomping peer edits.
- Implementing recoverable version history, CRDT state vector checkpoints, and snapshot rollbacks.
- Optimizing CRDT memory consumption and document compaction.

---

## Core Architecture Overview

```
Browser Client A (React + Monaco)
  ├── Monaco Editor Instance
  ├── Y.Doc (in-memory CRDT model)
  │    ├── Y.Text('monaco') <---> MonacoBinding <---> Monaco Model
  │    └── Awareness Protocol (cursor position, selection, user metadata)
  └── WebsocketProvider (y-websocket)
            │
            ▼ (Binary CRDT Sync Protocol: SyncStep1, SyncStep2, Update)
 WebSocket Server (Node.js / Express / Socket.IO / y-websocket)
  ├── Y.Doc per active room/file
  ├── In-Memory Awareness state broadcasting
  ├── Persistence Hook (PostgreSQL / Redis)
  └── Snapshot / Version History Engine
```

---

## 1. Yjs Document & Monaco Binding

### Document Setup
```typescript
import * as Y from 'yjs';
import { WebsocketProvider } from 'y-websocket';
import { MonacoBinding } from 'y-monaco';
import * as monaco from 'monaco-editor';

export function setupCollaborativeEditor(
  serverUrl: string,
  roomId: string,
  editor: monaco.editor.IStandaloneCodeEditor,
  currentUser: { name: string; color: string; id: string }
) {
  // 1. Initialize Document
  const doc = new Y.Doc();
  const yText = doc.getText('content');

  // 2. Establish Provider
  const provider = new WebsocketProvider(serverUrl, roomId, doc, {
    connect: true,
  });

  // 3. Awareness Setup (Presence & Cursors)
  const awareness = provider.awareness;
  awareness.setLocalStateField('user', {
    name: currentUser.name,
    color: currentUser.color,
    id: currentUser.id,
  });

  // 4. Monaco Binding with Awareness
  const model = editor.getModel();
  if (!model) throw new Error('Monaco model not initialized');

  const binding = new MonacoBinding(
    yText,
    model,
    new Set([editor]),
    awareness
  );

  return { doc, provider, binding, awareness };
}
```

### Critical Rules for Monaco Binding
- **Single Source of Truth**: Never directly call `editor.setValue()` on an active collaborative session; doing so resets the Yjs document and destroys concurrent edits.
- **Model Clean-up**: Always destroy the `MonacoBinding`, disconnect the `WebsocketProvider`, and destroy the `Y.Doc` on component unmount to prevent severe memory leaks and duplicate cursor ghosts.
- **Worker Configuration**: Ensure Monaco web workers (`editor.worker.js`, `ts.worker.js`) are properly bundled in Vite/Webpack so syntax highlighting and worker threads don't block the real-time CRDT sync loop.

---

## 2. Multi-Cursor & Awareness Presence

### Dynamic Cursor Styling
`y-monaco` injects CSS classes for each connected collaborator based on their client ID:
```css
/* Custom Cursor & Selection Styles */
.yRemoteSelection {
  background-color: rgba(250, 128, 114, 0.25);
  position: absolute;
}

.yRemoteSelectionHead {
  position: absolute;
  border-left: 2px solid salmon;
  border-top: 2px solid salmon;
  border-bottom: 2px solid salmon;
  height: 100%;
  box-sizing: border-box;
}

.yRemoteSelectionHead::after {
  content: attr(data-user);
  position: absolute;
  top: -1.4em;
  left: -2px;
  background-color: inherit;
  color: white;
  font-size: 10px;
  font-weight: 600;
  padding: 1px 4px;
  border-radius: 2px 2px 2px 0;
  pointer-events: none;
  white-space: nowrap;
}
```

### Awareness State Protocol
```typescript
// Listening for presence changes (collaborator list & active files)
awareness.on('change', () => {
  const states = Array.from(awareness.getStates().entries());
  const activeCollaborators = states
    .filter(([_, state]) => state.user)
    .map(([clientId, state]) => ({
      clientId,
      ...state.user,
    }));
  updateCollaboratorList(activeCollaborators);
});
```

---

## 3. Scoped Undo/Redo

A naive `Ctrl+Z` in a collaborative editor can undo a peer's edits! Yjs provides `Y.UndoManager` with tracked origins:

```typescript
// Track ONLY local edits in the undo manager
const undoManager = new Y.UndoManager(yText, {
  trackedOrigins: new Set([binding]), // Only capture changes originating from this editor binding
});

// Bind to Monaco or keyboard events
editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyZ, () => {
  undoManager.undo();
});

editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyMod.Shift | monaco.KeyCode.KeyZ, () => {
  undoManager.redo();
});
```

---

## 4. Recoverable Version History & Snapshots

### How CRDT Snapshots Work
In Yjs, history can be represented without mutating the current document using snapshots or update encoding:

```typescript
// Creating a Snapshot checkpoint
import * as Y from 'yjs';

export function createCheckpoint(doc: Y.Doc): Uint8Array {
  // Encodes the full document state into a compact binary vector
  return Y.encodeStateAsUpdate(doc);
}

// Persisting Snapshot to PostgreSQL
// Stored as BYTEA in Postgres with author_id, timestamp, commit_message

// Inspecting a Past Version (Read-only preview)
export function previewVersion(historicalUpdate: Uint8Array): string {
  const tempDoc = new Y.Doc();
  Y.applyUpdate(tempDoc, historicalUpdate);
  return tempDoc.getText('content').toString();
}

// Restoring a Previous Version (Creates a new CRDT change rather than breaking history)
export function restoreVersion(activeDoc: Y.Doc, historicalUpdate: Uint8Array, origin: any) {
  const tempDoc = new Y.Doc();
  Y.applyUpdate(tempDoc, historicalUpdate);
  const targetText = tempDoc.getText('content').toString();

  const activeText = activeDoc.getText('content');
  activeDoc.transact(() => {
    activeText.delete(0, activeText.length);
    activeText.insert(0, targetText);
  }, origin);
}
```

---

## 5. Server-Side Persistence & Scalability

### Database Schema (PostgreSQL)
```sql
CREATE TABLE document_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    update_data BYTEA NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE version_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    snapshot_data BYTEA NOT NULL,
    version_number INT NOT NULL,
    created_by UUID REFERENCES users(id),
    commit_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Document Compaction Pattern
To prevent an infinite list of tiny binary update rows:
1. Accumulate updates in memory or Redis stream.
2. Periodically (e.g. every 5 minutes or 100 updates), merge updates using `Y.mergeUpdates(updates)`.
3. Store the merged snapshot in PostgreSQL and archive/prune atomic update deltas.

---

## Quality Checklist
- [ ] Document destroys cleanly on component unmount without lingering listeners.
- [ ] UndoManager only tracks local editor origins.
- [ ] Awareness states include timeout/heartbeat so disconnected users disappear promptly.
- [ ] Binary CRDT updates are transmitted using ArrayBuffer/Uint8Array, not JSON strings.
- [ ] File switching correctly unbinds the old model and attaches the new Y.Text without resetting doc state.
