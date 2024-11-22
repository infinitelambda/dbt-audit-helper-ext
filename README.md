<!-- markdownlint-disable no-inline-html no-alt-text -->
# dbt-audit-helper-ext

<img align="right" width="150" height="150" src="./docs/assets/img/il-logo.png">

Extended Audit Helper solution 💪

Supporting:

- Snowflake (default)
- BigQuery

## Installation

- **Add to `packages.yml` file**:

  ```yml
  packages:
    - package: infinitelambda/audit_helper_ext
      version: [">=0.1.0", "<1.0.0"]
      # keep an eye on the latest version, and change it accordingly
  ```

  Or use the latest version from git:

  ```yml
  packages:
    - git: "https://github.com/infinitelambda/dbt-tags"
      revision: <release version or tag>
  ```

  And run `dbt deps` to install the package!

- **Initialize the resources**:

  ```bash
  dbt deps
  dbt run -s audit_helper_ext
  ```

  This step will create log table (`validation_log`) and the summary view on top (`validation_log_report`)

- **Generate the validation macros**:

  Firstly, we need to determine the location (database and schema) of the source tables:

  ** _If all source tables are in the same location_, we can use the environment variable to set these values:

  ```bash
  export SOURCE_SCHEMA=MY_SOURCE_SCHEMA
  export SOURCE_DATABASE=MY_SOURCE_DATABASE
  ```

  ** _If having multiple locations_, we can start to configure the location inside each dbt models' `config` block:

  ```sql
  {{
    config(
      ...
      audit_helper__source_database = 'MY_SOURCE_SCHEMA',
      audit_helper__source_schema = 'MY_SOURCE_DATABASE'
    )
  }}
  ...
  ```

  Then, we can start generating the validation macro files now.
  Let's say we need to validate all models in `03_mart` directory:

  ```bash
  python dbt_packages/audit_helper_ext/scripts/create_validation_macros.py models/03_mart
  ```

  Or just aim to validation a specific model which is `03_mart/dim_sales`:

  ```bash
  python dbt_packages/audit_helper_ext/scripts/create_validation_macros.py models/03_mart dim_sales
  ```

  Finally, check out your dbt project at the directory named `macros/validation`!

## Validation Strategy

This repo contains the **useful macros** to support for saving the historical validation results into the DWH table ([`validation_log`](./models/validation_log.sql)), together with the latest summary table ([`validation_log_report`](./models/validation_log_report.sql)).

There are 3 main types of validation:

- Count (`count`, [source](./macros/validation/get_validation_count.sql))
- Column by Column (`all_col`, [source](./macros/validation/get_validation_all_col.sql))
- Row by Row (`full`, [source](./macros/validation/get_validation_full.sql))

Additionally, we have the 4th type - `upstream_row_count` ([source](./macros/validation/get_upstream_row_count.sql)) which will be very useful to understand better the validtion context, for example, _the result might be up to 100% matched rate but there is 0 updates in the upstream models, hence there no updates in the final table, that means we can't not say surely it was a perfect match_.

Depending on projects, it might be vary in the strategy of validation. Therefore, in this package, we're suggesting 1 first approach that we've used successfully in the real-life migration project (Informatica to dbt).

**Context**: Our dbt project has 3 layers (staging, intermediate, and mart). Each mart model will have the independant set of upstream models, or it is the isolated pipeline for each mart model. We want to validate mart models only.

**Goal**: 100% matched rate ✅, >=99% is still good 🟡, and below 99% is unacceptable ❌

**Pre-requisites**: 2 consecutive snapshots (e.g. Day1, Day2) of both source data and mart tables

**Flow**:

- _Freeze the source data_, so we have `source__YYYYMMD1` and `source__YYYYMMD2`, `mart__YYYYMMD1` and `mart__YYYYMMD2`
- _Scenario 1: Validate the fresh run against D1_
  - Configure source yml to use `source__YYYYMMD1`
  - Run dbt to build mart tables, callled `mart_dbt`
  - Run validation macros to compare between `mart_dbt` vs `mart__YYYYMMD1` 👍
- _Scenario 2: Validate the incremental run against D2 based on D1_
  - Configure source yml to use `source__YYYYMMD2`
  - Clone `mart__YYYYMMD1` to `mart_dbt` to mimic that dbt should have the D1 data already (e.g. [clone_relation](./macros/dwh/clone_relation.sql))
  - Run incrementally dbt to build mart tables
  - Run validation macros to compare between `mart_dbt` vs `mart__YYYYMMD2` 👍👍

Finnally, check the validation log report, and decide what to do next steps:

🛩️ Sample report table on Snowflake:

![alt text](./docs/assets/img/snowflake-report-table.png)

💡 Optionally, let's build the [Sheet](https://docs.google.com/spreadsheets/d/1473_-s3R9D1Sx117fzqhY8SqjnqtfDmni6qKw_9tLXE/edit?usp=sharing) to communicate the outcome with clent, here is the BigQuery+GGSheet sample:

![alt text](./docs/assets/img/google-sheet-validation_resul.png)

## Demo

<div>
  <a href="https://www.loom.com/share/bb20f033d92544bab2009984d661176a">
    <p>dbt-audit-helper Extension - First Version - Watch Video</p>
  </a>
  <a href="https://www.loom.com/share/bb20f033d92544bab2009984d661176a">
    <img style="max-width:500px;" src="https://cdn.loom.com/sessions/thumbnails/bb20f033d92544bab2009984d661176a-7f1a1827496781a6-full-play.gif">
  </a>
</div>

## How to Contribute

`dbt-audit-helper-ext` is an open-source dbt package. Whether you are a seasoned open-source contributor or a first-time committer, we welcome and encourage you to contribute code, documentation, ideas, or problem statements to this project.

👉 See [CONTRIBUTING guideline](./CONTRIBUTING.md)

🌟 And finally, kudos to **our beloved OG Contributors** who orginally developed the macros and scripts in this package: [@William](https://www.linkedin.com/in/william-horel), [@Duc](https://www.linkedin.com/in/ducche), [@Csabi](https://www.linkedin.com/in/csaba-elekes-data), [@Adrien](https://www.linkedin.com/in/adrien-boutreau) & [@Dat](https://www.linkedin.com/in/datnguye)

## About Infinite Lambda

Infinite Lambda is a cloud and data consultancy. We build strategies, help organizations implement them, and pass on the expertise to look after the infrastructure.

We are an Elite Snowflake Partner, a Platinum dbt Partner, and a two-time Fivetran Innovation Partner of the Year for EMEA.

Naturally, we love exploring innovative solutions and sharing knowledge, so go ahead and:

🔧 Take a look around our [Git](https://github.com/infinitelambda)

✏️ Browse our [tech blog](https://infinitelambda.com/category/tech-blog/)

We are also chatty, so:

👀 Follow us on [LinkedIn](https://www.linkedin.com/company/infinite-lambda/)

👋🏼 Or just [get in touch](https://infinitelambda.com/contacts/)

[<img src="https://raw.githubusercontent.com/infinitelambda/cdn/1.0.0/general/images/GitHub-About-Section-1080x1080.png" alt="About IL" width="500">](https://infinitelambda.com/)
