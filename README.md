# AI Workshop - OpenEdge ABL Project

This project demonstrates the Business Entity pattern in OpenEdge ABL, using the Sports2000 database.

## Structure

- `src/business/` - Business entity classes and dataset definitions
- `src/` - GUI window procedures (.w files)
- `dump/` - Database schema (.df file)
- `doc/` - Documentation
- `.windsurf/` - Windsurf AI rules and workflows

## Prerequisites

- OpenEdge 12.8
- Sports2000 database

## Getting Started

1. Build the Sports2000 database: `ant db`
2. Open the project in Progress Developer Studio or Windsurf
3. Run `src/CustomerWin.w` or `src/ItemWin.w`
