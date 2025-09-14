{% set old_etl_relationi=ref('customer_orders') %}
{% set dbt_relation=ref('fct_customer_orders') %}

{{
    audit_helper.compare_relations(
        a_relation=old_etl_relationi,
        b_relation=dbt_relation,
        primary_key='order_id'
    )
}}