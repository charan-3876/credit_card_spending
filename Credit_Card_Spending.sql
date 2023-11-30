USE SQL_CREDIT_PROJECT;

select * from credit_card_transactions;

select distinct card_type from credit_card_transactions;--types of cards
select distinct exp_type from credit_card_transactions;--different types o expenditure
select min(transaction_date),max(transaction_date) from credit_card_transactions;

/*1) write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends */
select * from credit_card_transactions;

with cte1 as
(select city,sum(amount) as total_spend from credit_card_transactions group by city),
total_spent as
(select sum(cast(amount as bigint)) as total_amount from credit_card_transactions)
select top 5 cte1.*,round(total_spend*1.0/total_amount*100,2) as percentage_contribution from cte1,total_spent
order by total_spend desc;


/*2) write a query to print highest spend month and amount spent in that month for each card type*/
select * from credit_card_transactions;

with cte as
(select card_type,DATEPART(year,transaction_date) as yr,
DATEPART(month,transaction_date) as mt,sum(amount) as total_spend
from credit_card_transactions
group by card_type,DATEPART(year,transaction_date),DATEPART(month,transaction_date)
)
select * from
(select *,rank() over(partition by card_type order by total_spend desc) as rn from cte) a 
where rn=1


/*3- write a query to print the transaction details(all columns from the table) for each card type when
it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)*/
select * from credit_card_transactions;

with cte as
(select *,sum(amount) over(partition by card_type order by transaction_date,transaction_id) as total_spend 
from credit_card_transactions)
select * from(select *,rank() over(partition by card_type order by total_spend) as rn 
from cte where total_spend>=1000000) a
where rn=1;


/*4- write a query to find city which had lowest percentage spend for gold card type*/
select * from credit_card_transactions;

with cte1 as
(select city,card_type,sum(amount) as amount,
sum(case when card_type='Gold' then amount end) as gold_amount
from credit_card_transactions 
group by city,card_type)
select top 1 city,sum(gold_amount)*1.0/sum(amount) as gold_ratio
from cte1
group by city
having sum(gold_amount) is not null
order by gold_ratio


/*5- write a query to print 3 columns:city, highest_expense_type,lowest_expense_type 
(example format : Delhi , bills, Fuel)*/
select * from credit_card_transactions;

with cte as
(select city,exp_type,sum(amount) as total_amount 
from credit_card_transactions
group by city,exp_type)
select city,
max(case when rn_asc=1 then exp_type end) as lowest_expense_type,
min(case when rn_desc=1 then exp_type end) as highest_expense_type
from
(select *,
rank() over(partition by city order by total_amount desc) rn_desc,
rank() over(partition by city order by total_amount asc) rn_asc
from cte) a
group by city



/*6- write a query to find percentage contribution of spends by females for each expense type*/
select * from credit_card_transactions;

select exp_type,
sum(case when gender='F' then amount else 0 end)*1.0/sum(amount) as perentage_female_contribution 
from credit_card_transactions
group by exp_type
order by perentage_female_contribution 


/*7- which card and expense type combination saw highest month over month growth in Jan-2014*/
select * from credit_card_transactions;

with cte as
(select card_type,exp_type,
DATEPART(year,transaction_date) as yr,
DATEPART(month,transaction_date) as mt,
sum(amount) as total_spend
from credit_card_transactions
group by card_type,exp_type,DATEPART(year,transaction_date),DATEPART(month,transaction_date))
select top 1 *, (total_spend-prev_month_spend)*1.0/prev_month_spend as mom_growth
from
(select *,
lag(total_spend) over(partition by card_type,exp_type order by yr,mt) as prev_month_spend
from cte) a
where prev_month_spend is not null and yr=2014  and mt=1
order by mom_growth desc 



/*9- during weekends which city has highest total spend to total no of transcations ratio */
select * from credit_card_transactions;

--select *,datename(weekday,transaction_date) as day_name,datepart(weekday,transaction_date) as day_num 
--from credit_card_transactions
--where datepart(weekday,transaction_date) in (1,7)

select top 1 city,sum(amount)*1.0/count(1) as ratio 
from credit_card_transactions
where datepart(weekday,transaction_date) in (1,7)
group by city
order by ratio desc

/*9- which city took least number of days to reach its 500th transaction after the first transaction in that city*/
select * from credit_card_transactions;

select *,
ROW_NUMBER() over(partition by city order by transaction_date),
rank() over(partition by city order by transaction_date)
from credit_card_transactions; --to check the difference between row number and rank

with cte as
(select *,
ROW_NUMBER() over(partition by city order by transaction_date,transaction_id) as rn
from credit_card_transactions)
select top 1 city,datediff(day,min(transaction_date),max(transaction_date)) as datediff1
from cte
where rn=1 or rn=500
group by city
having count(1)=2
order by datediff1
