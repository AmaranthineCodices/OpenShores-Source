# Legacy database maintenance

These scripts operate directly on PostgreSQL databases and predate the Docker deployment.
They are retained as administrative references, not exposed through the supported `make`
interface.

Use `make server-reset` for the local Compose stack. Review connection settings, backups,
and every destructive SQL statement before running a script in this directory.
