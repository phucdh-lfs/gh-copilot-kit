---
description: "Use when writing, modifying, reviewing, or testing Go and Golang code, Go modules, CLI tools, services, handlers, repositories, or concurrency code."
applyTo: ["**/*.go", "go.mod", "go.sum"]
---
# Go Coding Standards

## Baseline

- Format Go code with `gofmt` or `go fmt ./...` before submitting changes.
- Keep packages cohesive and small; package names should be short, lowercase, and descriptive.
- Prefer simple, explicit code over clever abstractions.
- Accept interfaces at boundaries and return concrete types from constructors when practical.
- Keep exported identifiers documented with comments that start with the identifier name.
- Do not introduce global mutable state unless the package already uses it deliberately.
- Treat `context.Context` as the first parameter for request-scoped operations.

## Errors

- Return errors instead of panicking in library and service code.
- Wrap errors with `%w` when callers may need `errors.Is` or `errors.As`.
- Use sentinel errors sparingly and only when callers need stable branching behavior.
- Include useful operation context without duplicating the full call stack in every message.

```go
var ErrUserNotFound = errors.New("user not found")

func (s *UserService) User(ctx context.Context, id string) (User, error) {
	user, err := s.repo.FindUser(ctx, id)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return User{}, ErrUserNotFound
		}
		return User{}, fmt.Errorf("find user %q: %w", id, err)
	}

	return user, nil
}
```

## Interfaces

- Define interfaces where they are consumed, not where implementations are produced.
- Keep interfaces narrow and behavior-focused.
- Avoid interface names with redundant suffixes when the package context already makes the role clear.

```go
type userFinder interface {
	FindUser(ctx context.Context, id string) (User, error)
}

type UserService struct {
	repo userFinder
}
```

## Concurrency

- Prefer clear ownership of goroutines, channels, and cancellation paths.
- Do not start goroutines without a bounded lifetime or a documented owner.
- Use `errgroup` when multiple goroutines share cancellation and error handling.
- Protect shared mutable state with synchronization or remove the sharing.

```go
group, ctx := errgroup.WithContext(ctx)

for _, job := range jobs {
	job := job
	group.Go(func() error {
		return worker.Process(ctx, job)
	})
}

if err := group.Wait(); err != nil {
	return fmt.Errorf("process jobs: %w", err)
}
```

## HTTP And Services

- Keep handlers thin: parse input, call domain/application services, map responses.
- Validate request data close to the boundary.
- Do not let transport-specific types leak into domain logic unless the package is intentionally transport-owned.
- Use structured logging with request identifiers when the project has a logger standard.

```go
func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	id := r.PathValue("id")

	user, err := h.service.User(ctx, id)
	if err != nil {
		writeError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, user)
}
```

## Testing

- Prefer table-driven tests for related input and output cases.
- Use `t.Helper()` in test helpers.
- Keep tests deterministic; avoid sleeps, external services, and real clocks unless explicitly under test.
- Use `t.Setenv`, `t.TempDir`, and `context.WithTimeout` for isolated test setup.
- Test observable behavior rather than private implementation details.

```go
func TestNormalizeEmail(t *testing.T) {
	tests := []struct {
		name string
		in   string
		want string
	}{
		{name: "trims space", in: " User@Example.com ", want: "user@example.com"},
		{name: "keeps empty", in: "", want: ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := NormalizeEmail(tt.in)
			if got != tt.want {
				t.Fatalf("NormalizeEmail() = %q, want %q", got, tt.want)
			}
		})
	}
}
```

## Project Hygiene

- Run the narrowest relevant command first, then broaden when the change affects shared behavior.
- Typical validation commands are `go test ./...`, `go test ./path/to/package`, `go vet ./...`, and project-specific lint commands.
- Do not add dependencies without checking whether the standard library or existing project dependencies already solve the problem.
- Keep module changes intentional; review `go.mod` and `go.sum` after dependency updates.