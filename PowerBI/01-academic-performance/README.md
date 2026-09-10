# Student Performance Analytics Dashboard (Power BI)

An end-to-end Power BI project simulating the role of a data analyst at a school introducing a digital gradebook system. The project takes raw CSV exports through the full analytics lifecycle — data cleaning, star-schema modelling, DAX measure design, time intelligence, and a polished, multi-page interactive dashboard with consistent navigation.

## Project Overview

In the simulated scenario, school leadership wanted greater visibility into student performance: average grades by subject and class, trends over the academic year, the mix of grade types, geographic distribution of results, and which classes or subjects needed attention. This project delivers that visibility through a fully modelled Power BI report built from raw data.

The work was completed in four stages, each building on the last:

1. **Data preparation & modelling** — importing and cleaning six raw CSV sources, then building a proper star schema
2. **Core dashboard** — the first analytical report page (KPIs, charts, map, matrix)
3. **DAX measures & advanced interactivity** — a dedicated measures table, filter-context-aware calculations, drill-through and tooltip pages
4. **Time intelligence & dashboard integration** — built-in analytics (trend, forecast, percentiles), quick measures, and a unified, navigable multi-page dashboard

## Data Sources

Six raw CSV files simulating a school's gradebook system:

| File | Description |
|---|---|
| `students.csv` | Student roster (demographics, enrolment, class assignment) |
| `classes.csv` | Class reference table (grade level, section, homeroom teacher) |
| `teachers.csv` | Teacher roster (department, hire date) |
| `subjects.csv` | Subject reference table (core/elective, department hint) |
| `periods.csv` | Academic periods (year, term, start/end dates) |
| `grades.csv` | Fact table — individual grade records |

## Data Preparation (Power Query)

- Corrected data types across all tables (dates, numerics, text, booleans)
- Standardised date formats to the `en-US` locale
- Identified and handled invalid or blank values (e.g. missing `grade_type`)
- Validated primary keys for uniqueness and completeness across all dimension tables

## Data Model — Star Schema

A dedicated **`Calendar`** date dimension was built entirely in DAX, covering the full date range of the `grades` fact table, with `Date`, `Year`, `Month`, `Month Number` and `Year-Month` attributes.

**Fact table:** `grades`
**Dimension tables:** `students`, `classes`, `teachers`, `subjects`, `periods`, `Calendar`

All relationships are configured as **One-to-Many, Single direction**, with `Calendar[Date] → grades[grade_date]` anchoring the time dimension into the model.

## DAX Measures

All measures are centralised in a dedicated `_Measures` table. Highlights include:

- **Filter-context-aware measures** — e.g. `All Type Grades` (ignores `grade_type`), `Global Grades Count` (ignores `grade_type`, `academic_year`, and `department_hint`), built using `CALCULATE` and `ALL`
- **Negative grade tracking** — count and percentage of grades below the passing threshold
- **Time intelligence** — `Previous Grade`, `MoM_AG%` (month-over-month change), with explicit handling of blank periods to avoid false ±100% swings
- **Year-to-date** — both a Quick Measure (`TOTALYTD`) and a manually written equivalent, cross-validated to confirm identical results, with the fiscal year boundary aligned to the academic year (September–August)
- **Month-over-month difference** — a Quick Measure comparing each period's `Average Grade` to the prior period

## Report Pages

| Page | Purpose |
|---|---|
| **Academic Performance Overview** | Core KPI dashboard — average grades, timeline, grade-type breakdown, geographic map, subject/class matrix |
| **Class Performance** | Class-level deep dive — multi-row KPI card, negative-grade tracking, MoM trend, three slicers (grade type, academic year, department) |
| **Class Details** | Student-level breakdown *(drill-through target only)* — reached by drilling through from the class table on Class Performance |
| **Analytics & Time Intelligence** | Statistical analysis — trend lines, forecast with 95% confidence interval, percentiles, YTD validation |
| **MoM%_AG_Details** | Contextual detail *(tooltip page only)* — surfaced on hover over the month-over-month chart |

## Analytics Features

The trend chart on the Analytics & Time Intelligence page combines several native Power BI analytics elements on a continuous date axis:

- 25th percentile, median and 75th percentile, each with data labels
- A constant reference line at the passing threshold (6.0)
- A trend line
- A 3 month forecast with a shaded 95% confidence band

Each element uses a distinct colour, line style and weight so it remains visually separable from the underlying data series.

## Interactivity

- **Slicers**: grade type, academic year, department — synchronised across relevant pages via Sync Slicers
- **Cross-filtering**: charts filter one another without breaking measures that are deliberately designed to ignore certain filters
- **Drill-through**: Class Performance → Class Details, filtered by class, with a back button and validated so the drill-through total matches the source row exactly
- **Tooltip page**: hovering over the MoM% chart surfaces a dedicated report-page tooltip with previous, current and MoM% values
- **Navigation**: a consistent Page Navigator across all analytical pages, with the active page visually highlighted, filter context preserved on every transition

## Design Consistency

- A single colour palette (navy for primary series, warm accent tones for analytical overlays, red/bordeaux for negative values) applied across every page
- Standardised page structure: header → slicer row → KPI cards → analytical visuals
- Consistent KPI card formatting (two-decimal rounding throughout)
- Identical navigation button placement, size and style on every page

## Skills Demonstrated

- Power Query data cleaning and transformation
- Star-schema dimensional modelling
- DAX calendar table construction
- Filter context manipulation (`CALCULATE`, `ALL`, `ALLEXCEPT`)
- Time intelligence (`TOTALYTD`, month-over-month calculations, Quick Measures)
- Built-in analytics (trend lines, forecasting, percentiles)
- Drill-through and tooltip page design
- Multi-page report architecture with consistent navigation and styling

## Tools

- Power BI Desktop
- DAX
- Power Query 

---

*This project was completed as a structured series of exercises simulating a real-world education-sector analytics engagement, progressing from raw data to a finished, navigable analytical product.*

