
with

-- import cte

    orders as (select * from {{ source("jaffle_shop", "orders") }}),

    customers as (select * from {{ source("jaffle_shop", "customers") }}),

    base_payment as (select * from {{ source("stripe", "payment") }}),

-- logical cte
    
    payments as (select
                    orderid as order_id,
                    max(created) as payment_finalized_date,
                    sum(amount) / 100.0 as total_amount_paid
                from base_payment
                where status <> 'fail'
                group by 1
    ),

    paid_orders as (
        select
            orders.id as order_id,
            orders.user_id as customer_id,
            orders.order_date as order_placed_at,
            orders.status as order_status,
            payments.total_amount_paid,
            payments.payment_finalized_date,
            customers.first_name as customer_first_name,
            customers.last_name as customer_last_name
        from orders left join payments
            on orders.id = payments.order_id
        left join customers c on orders.user_id = customers.id
    ),

    customer_orders as (
        select
            customers.id as customer_id,
            min(order_date) as first_order_date,
            max(order_date) as most_recent_order_date,
            count(orders.id) as number_of_orders
        from customers c
        left join orders on orders.user_id = customers.id
        group by 1
    ),

    -- final cte

    final as (
        select
            p.*,
            row_number() over (order by p.order_id) as transaction_seq,
            row_number() over (
                partition by customer_id order by p.order_id
            ) as customer_sales_seq,
            case
                when c.first_order_date = p.order_placed_at then 'new' else 'return'
            end as nvsr,
            x.clv_bad as customer_lifetime_value,
            c.first_order_date as fdos
        from paid_orders p
        left join customer_orders as c using (customer_id)
        left outer join
            (
                select p.order_id, sum(t2.total_amount_paid) as clv_bad
                from paid_orders p
                left join
                    paid_orders t2
                    on p.customer_id = t2.customer_id
                    and p.order_id >= t2.order_id
                group by 1
                order by p.order_id
            ) x
            on x.order_id = p.order_id
        order by order_id
    )

-- simple select
select *
from final
