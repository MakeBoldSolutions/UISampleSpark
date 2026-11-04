# UISampleSpark (Web Distribution Summary)

A .NET 10 ASP.NET Core application showcasing multiple CRUD UI strategies (MVC, Razor Pages, AJAX modal CRUD, and PivotTable reporting) for Employees and Departments.

## Key Features
- MVC, Razor Pages, and Single Page style (AJAX + partial views)
- PivotTable.js employee data analysis
- Swagger/OpenAPI at `/swagger`
- Make Bold Spark brand theme with light (Cream) / dark (Ink) toggle
- In-memory EF Core data store
- Health check at `/health`
- Optional Azure Key Vault integration (via `VaultUri` env var)

## Tech Stack
- .NET 10 / ASP.NET Core
- Entity Framework Core (InMemory)
- Built-in ASP.NET Core OpenAPI + ApiTestSpark
- Make Bold Spark theme (`css/makebold.css`) on Bootstrap 5.3; brand fonts in `fonts/`
- Markdown rendering (Westwind)

## Run Locally
```pwsh
dotnet restore
cd UISampleSpark.UI
dotnet run
```
Browse: https://localhost:5001

## License
MIT � 2018-2025 Mark Hazleton
