create database ecommerce_db;
use  ecommerce_db;

# creates tables for eccomerce data 
create table customers(customer_id CHAR(36) PRIMARY KEY ,	
             customer_unique_id char(36),	
             customer_zip_code_prefix int,
             customer_city varchar(50),	
             customer_state varchar(50)) ;

CREATE TABLE orders (
    order_id CHAR(36) PRIMARY KEY,
    customer_id CHAR(36),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

                
CREATE TABLE products (
    product_id CHAR(36) PRIMARY KEY,
    product_uniqu_id CHAR(36),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);
ALTER TABLE products 
MODIFY COLUMN product_uniqu_id VARCHAR(100);

CREATE TABLE order_items (
    order_id CHAR(36),
    order_item_id INT,
    product_id CHAR(36),
    seller_id CHAR(36),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);


CREATE TABLE category (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);


CREATE TABLE geolocation (
    geolocation_id INT AUTO_INCREMENT PRIMARY KEY,
    geolocation_lat DECIMAL(10,6),
    geolocation_lng DECIMAL(10,6),
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
);
ALTER TABLE geolocation
ADD COLUMN geolocation_zip_code_prefix INT;


CREATE TABLE order_review (
    review_id CHAR(36) PRIMARY KEY,
    order_id CHAR(36),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);


CREATE TABLE order_payment (
    order_id CHAR(36),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);


CREATE TABLE seller (
    seller_id CHAR(36) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);


select * from category;
select * from geolocation;
select * from customers;
select * from orders;
select * from order_payment;
select * from order_review;
select * from sellers;

# count od data 

select count(*) as count_customer from customers;
select count(*) as count_category from category ;
select count(*) as count_products from products ;
select count(*) as count_orders from orders ;

#remove null values 
select * from customers 
where customer_city is null ;

select * from orders 
where order_id is null ;

#Data analysis from ecommerce data 

#1.Top 10 cities from no of customers 
select customer_city ,count(*) as total_customers 
from customers 
group by customer_city 
order by total_customers desc 
limit 10 ;

#2 repeat purchase rate 
select count(distinct customer_id ) as total_customers_name,
sum(case when order_count >1 then 1 else 0 end) as repeat_customers,
Round(sum(case when order_count > 1 then 1 else 0 end) /count(distinct customer_id) * 100,2) as repeat_rate_percent
from (select customer_id ,count(order_id) as order_count
      from orders 
      group by customer_id)as t;
      
#3.Total revenue per month with view
create view monthly_revenue as
select date_format(order_purchase_timestamp, '%Y-%m') as month ,
round(sum(p.payment_value),2) as total_revenue
from orders o 
join order_payment p on 
o.order_id = p.order_id 
group by month 
order by month ;
select * from monthly_revenue;

select * from products ;
select * from category;

# 4.top 10 products categories by revenue 

select pr.product_category_name , 
round(sum(p.payment_value),2)as total_revenue
from order_items oi
join products pr on oi.product_id = pr,product_id
join order_payment p on oi.order_id = p.order_id
group by pr.product_category_name 
order by total_revenue desc 
limit 10 ;


#5.Average order value 
create view AOV as 
select round(sum(p.payment_value) / count(distinct o.order_id),2)as average_order_value
from orders o 
join order_payment p 
on o.order_id = p.order_id ;
select * from AOV;

#6.average delivery time 
select round(avg(datediff(order_delivered_customer_date ,order_purchase_timestamp)),2) as avg_delivery_time
from orders 
where order_status ='delivered';

#7.delivey performance by state 

select c.customer_state ,
round(avg(datediff(order_delivered_customer_date , order_purchase_timestamp)),2) as avg_delivery_days
from orders o 
join customers c on o.customer_id = c.customer_id 
where order_status = 'delivered'
group by c.customer_state 
order by avg_delivery_days;

#8.average review score by product_id
select p.product_id ,
round(avg(r.review_score),2) as avg_review
from order_review r 
join orders o on r.order_id = o.order_id 
join order_items oi on o.order_id = oi.order_id 
join products p on oi.product_id = p.product_id 
group by p.product_id 
order by avg_review desc 
limit 10;

#9.correlation between delivery time and review score 
select 
round(avg(datediff(order_delivered_customer_date ,order_purchase_timestamp)),2)as avg_delivey_days ,
round(avg(r.review_score),2) as avg_review_score 
from orders o 
join order_review r on 
o.order_id= r.order_id 
where o.order_status = 'delivered';

#10.top 10 sellers by revenue 
create table ecommerce_sell as 
select s.seller_id , s.seller_city,
round(sum(p.payment_value),2) as total_sales
from order_items oi 
join sellers s on oi.seller_id = s.seller_id 
join order_payment p on oi.order_id = p.order_id 
group by s.seller_id , s.seller_city 
order by total_sales desc 
limit 10;
select * from ecommerce_sell;

# 11.revenue vs cancellation 
select order_status ,
count(order_id) as total_orders,
round(sum(p.payment_value),2) as total_revenue 
from orders o 
join order_payment p on o.order_id = p.order_id 
group by order_status
order by total_revenue desc;

#12.cohort analysis (customer retention) 

select 
date_format(first_order_date, '%Y-%m') as cohort_month ,
date_format(o.order_purchase_timestamp , '%Y-%M') as order_month ,
count(distinct o.customer_id) as active_customers
from orders o 
join (select customer_id , min(order_purchase_timestamp)as first_order_date 
      from orders 
      group by customer_id) first_order on o.customer_id =first_order,customer_id
      group by cohort_month , order_month
      order by cohort_month , order_month ;

#13.payment method distribution 

select payment_type ,
count(*) as num_transactions,
round(sum(p.payment_value ),2) as total_revenue
from order_payment p 
group by payment_type 
order by total_revenue desc ;

#14.save insight 
create table ecommerce_insight as 
 select  date_format(order_purchase_timestamp, '%Y-%m') as month ,
 round(sum(p.payment_value ),2) as total_revenue 
 from orders o 
 join order_payment p on o.order_id = p.order_id 
 group by month ;
 select * from ecommerce_insight;
 
 #15.monthly revenue report - store procedure 
 DELIMITER $$

CREATE PROCEDURE GetMonthlyRevenue(IN input_month VARCHAR(7))
BEGIN
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(p.payment_value), 2) AS total_revenue,
        ROUND(SUM(p.payment_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
    FROM orders o
    JOIN order_payment p ON o.order_id = p.order_id
    WHERE DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') = input_month
    GROUP BY month;
END $$

DELIMITER ;

call GetMonthlyRevenue('2018-3');

#16.top selling products - store procedure 
Delimiter $$
create procedure GetTopSellingproducts (IN top_n int)
begin 
select oi.product_id ,
count(oi.order_id) as total_orders,
round(sum(oi.price),2) as total_sales 
from order_items oi 
group by oi.product_id 
order by total_sales desc
limit top_n ;
 END $$  
delimiter ;

call GetTopSellingProducts(25);

#create procedure for get monthly sales 
   DELIMITER //
CREATE PROCEDURE sp_monthly_sales()
BEGIN
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
        ROUND(SUM(pay.payment_value), 2) AS total_revenue
    FROM orders o
    JOIN order_payment pay ON o.order_id = pay.order_id
    GROUP BY month
    ORDER BY month;
END //
DELIMITER ; 

CALL sp_monthly_sales();



#create view as summary of my business 
CREATE VIEW business_summary AS
SELECT 
    (SELECT COUNT(DISTINCT c.customer_id) FROM customers c) AS total_customers,
    (SELECT COUNT(DISTINCT o.order_id) FROM orders o) AS total_orders,
    (SELECT ROUND(SUM(p.payment_value), 2) FROM order_payment p) AS total_revenue,
    (SELECT ROUND(SUM(p.payment_value)/COUNT(DISTINCT o.order_id), 2)
        FROM order_payment p
        JOIN orders o ON o.order_id = p.order_id) AS avg_order_value,
    (SELECT ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 2)
        FROM orders o
        WHERE o.order_status = 'delivered') AS avg_delivery_time;
     
     select * from business_summary ;
     
	#creat eprocedure for summary report 
    delimiter $$ 
    create procedure business_summary_reports()
    begin
     SELECT 
        (SELECT COUNT(DISTINCT c.customer_id) FROM customers c) AS total_customers,
        (SELECT COUNT(DISTINCT o.order_id) FROM orders o) AS total_orders,
        (SELECT ROUND(SUM(p.payment_value), 2) FROM order_payment p) AS total_revenue,
        (SELECT ROUND(SUM(p.payment_value)/COUNT(DISTINCT o.order_id), 2)
            FROM order_payment p
            JOIN orders o ON o.order_id = p.order_id) AS avg_order_value,
        (SELECT ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 2)
            FROM orders o
            WHERE o.order_status = 'delivered') AS avg_delivery_time,
            (select c.customer_state ,
round(avg(datediff(order_delivered_customer_date , order_purchase_timestamp)),2) as avg_delivery_days
from orders o 
join customers c on o.customer_id = c.customer_id 
where order_status = 'delivered'
group by c.customer_state 
order by avg_delivery_days);
            end$$
      call business_summary_report;      

     
     
     
     

# create some view because PowerBi can't recognized UUID as text 
CREATE OR REPLACE VIEW view_orders AS
SELECT 
    CAST(order_id AS CHAR(36)) AS order_id,
    CAST(customer_id AS CHAR(36)) AS customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM orders;

CREATE OR REPLACE VIEW products_textview AS
SELECT 
    CAST(product_id AS CHAR(36)) AS product_id,
    product_uniqu_id,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM products;

CREATE OR REPLACE VIEW order_payment_textview AS
SELECT 
    CAST(order_id AS CHAR(36)) AS order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM order_payment;

CREATE OR REPLACE VIEW order_review_textview AS
SELECT 
    CAST(review_id AS CHAR(36)) AS review_id,
    CAST(order_id AS CHAR(36)) AS order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
FROM order_review;


CREATE OR REPLACE VIEW order_item_textview AS
SELECT 
    CAST(order_id AS CHAR(36)) AS order_id,
    CAST(product_id AS CHAR(36)) AS product_id,
    CAST(seller_id AS CHAR(36)) AS seller_id,
    shipping_limit_date,
    price,
    freight_value
FROM order_items;


CREATE OR REPLACE VIEW customers_textview AS
SELECT 
    CAST(customer_id AS CHAR(36)) AS customer_id,
    CAST(customer_unique_id AS CHAR(36)) AS customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM customers;


#make order date column different (order_purchase_date TO date)
SELECT 
    YEAR(order_purchase_timestamp) AS order_year,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_year
ORDER BY order_year;

#create table seperate that only have dates columns 
CREATE TABLE order_dates AS
SELECT DISTINCT
    DATE(order_purchase_timestamp) AS order_date
FROM orders
WHERE order_purchase_timestamp IS NOT NULL
ORDER BY order_date;
select * from order_dates;

ALTER TABLE order_dates
ADD COLUMN order_year INT,
ADD COLUMN order_month INT,
ADD COLUMN order_month_name VARCHAR(20),
ADD COLUMN order_quarter VARCHAR(10),
ADD COLUMN order_month_year VARCHAR(20);


SET SQL_SAFE_UPDATES = 0;
UPDATE order_dates
SET 
    order_year = YEAR(order_date),
    order_month = MONTH(order_date),
    order_month_name = DATE_FORMAT(order_date, '%b'),
    order_quarter = CONCAT('Q', QUARTER(order_date)),
    order_month_year = DATE_FORMAT(order_date, '%b %Y');
    
    
#some cte use cases 
#Returning VS New customers 
WITH customer_orders AS (
    SELECT customer_id, COUNT(order_id) AS total_orders
    FROM orders
    GROUP BY customer_id
)
SELECT 
    CASE 
        WHEN total_orders = 1 THEN 'New Customer'
        ELSE 'Returning Customer'
    END AS customer_type,
    COUNT(*) AS customer_count
FROM customer_orders
GROUP BY customer_type;
    
 #Find to 5 cities by AOV 

   
    WITH city_sales AS (
        SELECT 
            c.customer_city,
            SUM(p.payment_value) AS total_revenue,
            COUNT(DISTINCT o.order_id) AS total_orders
        FROM orders o
        JOIN customers c ON o.customer_id = c.customer_id
        JOIN order_payment p ON o.order_id = p.order_id
        GROUP BY c.customer_city
    )
    SELECT 
        customer_city,
        ROUND(total_revenue / total_orders, 2) AS avg_order_value
    FROM city_sales
    ORDER BY avg_order_value DESC
    LIMIT 5;




