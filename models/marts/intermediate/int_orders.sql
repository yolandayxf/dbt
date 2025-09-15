with

-- import cte

    orders as (select * from {{ source("jaffle_shop", "orders") }}),

    customers as (select * from {{ source("jaffle_shop", "customers") }}),

    payment as (select * from {{ source("stripe", "payment") }}),

-- logical cte
    
    completed_payments as (select
                    orderid as order_id,
                    max(created) as payment_finalized_date,
                    sum(amount) / 100.0 as total_amount_paid
                from payment
                where status <> 'fail'
                group by 1
    ),

    paid_orders as (
        select
            orders.id as order_id,
            orders.user_id as customer_id,
            orders.order_date as order_placed_at,
            orders.status as order_status,
            completed_payments.total_amount_paid,
            completed_payments.payment_finalized_date,
            customers.first_name as customer_first_name,
            customers.last_name as customer_last_name
        from orders 
        left join completed_payments on orders.id = completed_payments.order_id
        left join customers on orders.user_id = customers.id
    )

    select * from paid orders