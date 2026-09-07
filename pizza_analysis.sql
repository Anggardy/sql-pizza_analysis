select * from pizzaSales_001.pizza_order;
select * from pizzaSales_001.pizza_order_detail;
select * from pizzaSales_001.pizza_price;
select * from pizzaSales_001.pizza_type;

-- Problem 1: Executive KPI Overview (Performa Penjualan Dasar)
-- Berapa total pendapatan kotor (gross revenue), total pizza yang berhasil terjual, total transaksi (order), berapa rata-rata nilai belanja pelanggan per transaksi (Average Order Value / AOV)?"
-- Target Output: Ringkasan 1 baris berisi: total_revenue, total_pizzas_sold, total_orders, average_order_value.

with kpi as (
  select 
    round(sum(pd.quantity * pp.price), 2) as total_revenue,
    sum(pd.quantity) as total_pizza_sold,
    count(distinct pd.order_id) as total_orders
  from `pizzaSales_001.pizza_order_detail` as pd
  left join `pizzaSales_001.pizza_price` as pp 
    on pd.pizza_id=pp.pizza_id
) 
select
  total_revenue,
  total_pizza_sold,
  total_orders,
  round(total_revenue /  total_pizza_sold, 2) as AoV
from kpi;


-- ----------------------------------------
-- Problem 2: Menu Optimization – Best & Worst Performing Pizzas
-- Petakan 5 menu pizza teratas (top 5) dan 5 menu pizza terbawah (bottom 5) berdasarkan total revenue 

-- Target Output: Daftar menu pizza (pizza_name), kategori, dan total revenue.

with pizza_revenue as (
  select 
    pt.name as pizza_name,
    pt.category as kategori,
    round(sum(pd.quantity * pp.price), 2) as total_revenue
  from `pizzaSales_001.pizza_order_detail` as pd
  join `pizzaSales_001.pizza_price` as pp 
    on pd.pizza_id=pp.pizza_id
  join `pizzaSales_001.pizza_order` as po 
    on pd.order_id=po.order_id
  join `pizzaSales_001.pizza_type` as pt
   on pp.pizza_type_id=pt.pizza_type_id
  group by pt.name, kategori
),
ranked_pizza as (
  select 
    *,
    row_number() over(order by total_revenue desc) as rank_highest,
    row_number() over(order by total_revenue asc) as rank_lowest
  from pizza_revenue
)
select 
  'Top 5' as performance_group,
  rank_highest as rank_position,
  pizza_name,
  kategori,
  total_revenue
from ranked_pizza
where rank_highest <= 5

union all

select 
  'Bottom 5' as performance_group,
  rank_highest as rank_position,
  pizza_name,
  kategori,
  total_revenue
from ranked_pizza
where rank_lowest <= 5
order by rank_position asc;


-- ----------------------------------------
-- Problem 3: Operational Peak Hours & Staffing Allocation
-- analisis tren volume pesanan berdasarkan jam dalam sehari (hour of day) & analisis Jam berapa saja yang merupakan jam tersibuk (rush hours)?

-- Target Output: Tabel distribusi jam (order_hour), jumlah pesanan (total_orders), dan persentase pesanan terhadap total transaksi harian

select 
  extract(Hour from time) as order_hour,
  count(order_id) as total_orders,
  round(
    count(order_id) * 100 / sum(count(order_id)) over(), 2
  ) as percentage_order
from `pizzaSales_001.pizza_order` 
group by order_hour
order by total_orders;


-- ----------------------------------------
-- Problem 4: Customer Size Preference & Revenue Contribution by Category
-- buatkan breakdown total penjualan dan kontribusi pendapatan (persentase dari total revenue) berdasarkan kategori pizza (category) dan ukuran pizza (size)."

-- Target Output: category, size, total_sold, revenue, %_revenue_contribution.

SELECT
  pt.category,
  pp.size,
  SUM(pd.quantity) AS total_pizzas_sold,
  ROUND(SUM(pd.quantity * pp.price), 2) AS total_revenue,
  ROUND(
    SUM(pd.quantity * pp.price) * 100.0 / SUM(SUM(pd.quantity * pp.price)) OVER(), 
    2
  ) AS revenue_contribution_pct
FROM `pizzaSales_001.pizza_order_detail` AS pd
JOIN `pizzaSales_001.pizza_price` AS pp 
  ON pd.pizza_id = pp.pizza_id
JOIN `pizzaSales_001.pizza_type` AS pt 
  ON pp.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category, pp.size
ORDER BY pt.category, revenue_contribution_pct DESC;


-- ----------------------------------------
-- Problem 5: Cumulative Revenue Growth Trend (Day-by-Day)
-- melihat laju pertumbuhan pendapatan kumulatif dari hari ke hari sepanjang tahun berjalan untuk melihat kestabilan cash flow."

-- Target Output: order_date, daily_revenue, running_total_revenue.

with daily_revenue as (
  select
    po.date as order_date,
    round(sum(pp.price * pd.quantity), 2) as daily_revenue
  from `pizzaSales_001.pizza_order_detail` as pd
  join `pizzaSales_001.pizza_price` as pp 
    on pd.pizza_id=pp.pizza_id
  join `pizzaSales_001.pizza_order` as po 
    on pd.order_id=po.order_id
  group by order_date
)
select 
 order_date,
 daily_revenue,
 round(
  sum(daily_revenue) over(order by order_date asc), 2
 ) as running_total_revenue
from 
  daily_revenue
group by order_date;
