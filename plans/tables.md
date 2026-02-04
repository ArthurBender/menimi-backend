# Tables Configuration (V1)

This document captures the initial schema plan for migrations.

## users
- id: bigserial primary key
- first_name: string, null: false
- last_name: string, null: false
- email: string, null: false, unique
- timezone: string, null: false, default: "UTC"
- created_at: datetime, null: false
- updated_at: datetime, null: false

Indexes:
- unique index on email

## tasks
- id: bigserial primary key
- user_id: bigint, null: false, foreign key -> users.id
- title: string, null: false
- description: text, null: true
- rrule: string, null: true
- starts_at: datetime, null: false
- timezone: string, null: false
- carry_over: boolean, null: false, default: false
- active: boolean, null: false, default: true
- created_at: datetime, null: false
- updated_at: datetime, null: false

Indexes:
- index on user_id
- index on active

Notes:
- rrule can be null for single-occurrence tasks
- starts_at is the DTSTART anchor for recurrence evaluation

## task_occurrences
- id: bigserial primary key
- task_id: bigint, null: false, foreign key -> tasks.id
- occurred_at: datetime, null: false
- status: string, null: false (enum: missed, canceled, done)
- created_at: datetime, null: false
- updated_at: datetime, null: false

Indexes:
- index on task_id
- composite index on [task_id, occurred_at]

Notes:
- occurrences are only created for resolved states (missed, canceled, done)
- scheduled instances are derived on the client from rrule + starts_at
