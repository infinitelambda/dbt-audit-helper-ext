<!-- markdownlint-disable no-inline-html no-alt-text -->
# dbt-audit-helper-ext

<img align="right" width="150" height="150" src="./docs/assets/img/il-logo.png">

<!-- [![dbt-hub](https://img.shields.io/badge/Visit-dbt--hub%20↗️-FF694B?logo=dbt&logoColor=FF694B)](https://hub.getdbt.com/infinitelambda/audit_helper_ext)
[![support-dbt](https://img.shields.io/badge/support-dbt%20v1.6+-FF694B?logo=dbt&logoColor=FF694B)](https://docs.getdbt.com?ref=infinitelambda) -->

Extended Audit Helper solution 💪

## Installation

- Copy this repo to your dbt project. We will treat it as the local package until it's published
- Add to `packages.yml` or `dependencies.yml` file:

```yml
packages:
  - local: dbt-audit-helper-ext
```

- Deploy the resources:

```bash
dbt deps
dbt run -s audit_helper_ext
```

## Validation Strategy

TODO

## Demo

TODO

## How to Contribute

`dbt-audit-helper-ext` is an open-source dbt package. Whether you are a seasoned open-source contributor or a first-time committer, we welcome and encourage you to contribute code, documentation, ideas, or problem statements to this project.

👉 See [CONTRIBUTING guideline](./CONTRIBUTING.md)

<!-- 🌟 And then, kudos to **our beloved Contributors**:

<a href="https://github.com/infinitelambda/dbt-audit-helper-ext/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=infinitelambda/dbt-audit-helper-ext" alt="Contributors" />
</a> -->

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
