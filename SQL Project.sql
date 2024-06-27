
use lb15th 
create table railways(Transaction_ID varchar(25) not null,Date_of_Purchase varchar(25),Time_of_Purchase varchar(15),Purchase_Type varchar(15),
Payment_Method varchar(20),Railcard varchar(15),Ticket_Class varchar(20),Ticket_Type varchar(20),Price varchar(25),Departure_Station varchar(100),
Arrival_Destination varchar(100),Date_of_Journey varchar(25),Departure_Time varchar(25),Arrival_Time varchar(25),Actual_Arrival_Time varchar(25),
Journey_Status varchar(20),Reason_for_Delay varchar(30),Refund_Request varchar(10))



bulk insert railways
from 'C:\Users\aman1\OneDrive\Desktop\June placement project\railway.csv'
with (
fieldterminator=',',
rowterminator = '\n',
Firstrow = 2,
tablock
)


--- cleaning of date of purchase column
update railways
set Date_of_Purchase = replace(Date_of_Purchase,'%','-')
where Date_of_Purchase = '31-12%2023'

select * from railways
where Date_of_Purchase = '31-12-2023'

UPDATE railways
SET Date_of_Purchase = Try_CONVERT(date, Date_of_Purchase,105);


select distinct Date_of_Purchase from railways

--- cleaning of price column

SELECT DISTINCT Price 
FROM railways
WHERE Price LIKE '%--%'
   OR Price LIKE '%ú%'
   OR Price LIKE '%A%'
   OR Price LIKE '%$%'
   OR Price LIKE '%&^%'


update railways
set Price = replace(Price,'A','')

update railways
set Price = replace(Price,'$','')

update railways
set Price = replace(Price,'--','')

update railways
set Price = replace(Price,'&^','')

update railways
set Price = replace(Price,'ú','')


UPDATE railways
SET Price = CONVERT(int, Price);

---cleaning of date_of_journey column

select * from railways
where Date_of_Journey = '06--02-2024'

update railways
set Date_of_Journey = REPLACE(Date_of_Journey,'*','-')

update railways
set Date_of_Journey = REPLACE(Date_of_Journey,'--','-')

UPDATE railways
SET Date_of_Journey = CONVERT(date, Date_of_Journey,105);

---cleaning of time_of_purchase column

UPDATE railways
SET Time_of_Purchase = CAST(Time_of_Purchase AS time);

UPDATE railways
SET Time_of_Purchase = CONVERT(time(0), Time_of_Purchase);

--- cleaning of departure_time column

select distinct Departure_Time from railways
where Departure_Time like '%::%'

update railways
set Departure_Time = REPLACE(Departure_Time,'::',':')

update railways
set Departure_Time = cast(Departure_Time As time)

update railways
set Departure_Time =CONVERT(time(0),Departure_Time)

select * from railways


---cleaning of arrival_time column

select distinct arrival_time from railways

update railways
set arrival_time = cast(arrival_time As time)

update railways
set arrival_time =CONVERT(time(0),arrival_time)

---cleaning of actual_arrival_time column

select distinct Actual_Arrival_Time from railways
where Actual_Arrival_Time like '%::%'

update railways
set Actual_Arrival_Time = REPLACE(Actual_Arrival_Time,'::',':')

update railways
set Actual_Arrival_Time = cast(Actual_Arrival_Time As time)

update railways
set Actual_Arrival_Time =CONVERT(time(0),Actual_Arrival_Time)

select * from railways

--- cleaning of reason_for_delay column

UPDATE railways
SET Reason_for_Delay = ISNULL(NULLIF(Reason_for_Delay, ''), 'No Failure');

--- cleaning done


---1.	Identify Peak Purchase Times and Their Impact on Delays:

--Identify Peak Purchase Times 

with purchasetime as(
	select
		DATEPART(hour,Time_of_Purchase) as purchase_hour,count(*) as purchase_cout from railways
		group by DATEPART(hour,Time_of_Purchase)
),

--Their Impact on Delays

delays as (
	select
		DATEPART(hour,Time_of_Purchase) as purchase_hour,
		avg(datediff(MINUTE,Arrival_Time,coalesce(Actual_Arrival_Time,Arrival_Time))) as average_delay from railways
		where Journey_Status = 'Delayed'
		group by datepart(hour,Time_of_Purchase)
)

select pt.purchase_hour,
	pt.purchase_cout,
	d.average_delay from purchasetime pt
left join delays d
on pt.purchase_hour = d.purchase_hour
order by pt.purchase_cout desc


select Transaction_ID,count(*) as purchase_count from railways
group by Transaction_ID
having count(*) > 3


---2.	Revenue Loss Due to Delays with Refund Requests

select sum(Price) as TotalRevenueLoss from railways
where Journey_Status = 'Delayed' and Refund_Request = 'Yes'

---3.	Impact of Railcards on Ticket Prices and Journey Delays: 

select Railcard,
	avg(price) as AverageTicketPrice,
	SUM(case when Journey_Status = 'Delayed' then 1 else 0 end) * 100.0 / COUNT(*) AS DelayRate
	from railways
	group by railcard

---4.	Journey Performance by Departure and Arrival Stations:

select Departure_Station,
	   Arrival_Destination,
	   avg(datediff(minute,Arrival_Time,Actual_Arrival_Time)) AS AverageDelay from railways
	   where Journey_Status = 'Delayed'
	   group by Departure_Station,Arrival_Destination
	   order by avg(datediff(minute,Arrival_Time,Actual_Arrival_Time)) desc

---5.	Revenue and Delay Analysis by Railcard and Station

select Railcard,
	   Departure_Station,
	   Arrival_Destination,
	   sum(price) as TotalRevenue,
	   avg(case when journey_Status = 'Delayed' then DATEDIFF(Minute,Arrival_Time,Actual_Arrival_Time) 
	   else 0
	   end) AS AverageDelay from railways
	   group by Railcard,Departure_Station,Arrival_Destination


---6.	Journey Delay Impact Analysis by Hour of Day

select DATEPART(hour,Departure_Time) hourofday,
	   avg(case when journey_Status = 'Delayed' then DATEDIFF(Minute,Arrival_Time,Actual_Arrival_Time) 
	   else 0
	   end) AS AverageDelay from railways
	   group by DATEPART(hour,Departure_Time)
	   order by AverageDelay desc

