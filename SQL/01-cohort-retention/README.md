# Cohort Retention Analysis

## Overview
This project analyses user retention by signup cohort, activity month
and promotional acquisition status.

The analysis uses PostgreSQL and was performed in DBeaver. The source
data contains signup and event dates stored as free-text strings in
different formats, requiring data cleaning and date standardisation
before the cohort analysis.

## Objective
The goal is to prepare a cohort table showing the number of unique
active users for each:

- signup cohort month
- month_offset (user tenure in months)
- promo signup status

The observation period covers January to June 2025.

## SQL Approach
The query consists of three CTEs and a final aggregation:

- **users_parsed** — cleans and standardises `signup_datetime`
- **events_parsed** — cleans and standardises `event_datetime`
- **user_activity** — joins users and events and derives
  `cohort_month`, `activity_month` and `month_offset`
- **Final SELECT** — counts unique active users by promo status,
  cohort month and month offset

The analysis excludes records with missing or invalid dates, missing
event types and test events. Registration events are retained as
month 0 activity.

An earlier version normalised the date components (LPAD, day_norm, month_norm, year_norm) 
before conversion. I ultimately chose direct format detection with CASE and to_timestamp() 
because it is simpler and sufficient for this project, while still handling both supported 
date formats correctly.

## Google Sheets Analysis
The SQL output was exported to Google Sheets, where the cohort table
was prepared and retention rates were calculated.

**[View the cohort analysis in Google Sheets →](https://docs.google.com/spreadsheets/d/1LzF0mxAypZOrtERvhhvQqyykkcgQWQo8gajBfjkfO7w/edit?usp=drive_link)**

## Tools
- PostgreSQL
- DBeaver
- Google Sheets

## Files
- `cohort_analysis.sql` — SQL query used to prepare the cohort data

## Skills demonstrated
SQL (CTEs, data cleaning, date parsing, aggregation) · PostgreSQL · DBeaver · Cohort analysis · Google Sheets
