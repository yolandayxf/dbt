with

-- import cte

    orders as (select * from {{ ref('stg_jaffle_shop__orders') }}),

    customers as (select * from {{ ref('stg_jaffle_shop__customers') }}),

    payment as (select * from {{ ref('stg_stripe__payments') }}),

-- logical cte
    
    completed_payments as (select
                    order_id,
                    max(payment_created_at) as payment_finalized_date,
                    sum(payment_amount) as total_amount_paid
                from payment
                where payment_status <> 'fail'
                group by 1
    ),

    paid_orders as (
        select
            orders.order_id,
            orders.customer_id,
            orders.order_placed_at,
            orders.order_status,

            completed_payments.total_amount_paid,
            completed_payments.payment_finalized_date,

            customers.customer_first_name,
            customers.customer_last_name
        from orders 
        left join completed_payments on orders.order_id = completed_payments.order_id
        left join customers on orders.customer_id = customers.customer_id
    )

    select * from paid_orders