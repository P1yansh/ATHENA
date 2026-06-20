// OpenAPI Fetch client wrapped with TanStack Query
// Requires generation of schema.ts from the backend OpenAPI spec

import createFetchClient from "openapi-fetch";
// import type { paths } from "./schema"; // Uncomment after running openapi-typescript

export const apiClient = createFetchClient<any /* replace with paths */>({
  baseUrl: "/api",
});
