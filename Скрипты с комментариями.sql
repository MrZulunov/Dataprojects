------  Cоздаём таблицу куда будем импортировать данные и присваиваем тип к каждому столбцу:  

create table auto_service (
	date date,
	service text ,
	service_addr text ,
	w_name text ,
	w_exp int ,
	w_phone text ,
	wages int ,
	card text ,
	payment numeric ,
	pin text ,
	"name" text ,
	phone text ,
	email text ,
	"password" text ,
	car text ,
	mileage int ,
	vin text ,
	car_number text ,
	color text 
)

 
 
 ------ Данным запросом можно проверить столбец на наличие дубликатов. Дли примера возьмем столбец "car"
 select car, count(*) AS quantity
from auto_service as2 
group by car
having count(*) > 1 


------ Добавляем id в таблицу 

ALTER TABLE   auto_service
ADD COLUMN id SERIAL PRIMARY KEY 

------ Убираем дубликаты 

WITH RankedRows AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY date, service, service_addr, w_name, w_exp, w_phone, wages, card, payment, pin, name, phone, email, password, car, mileage, vin, car_number, color ORDER BY date) as rn
    FROM auto_service
),
RowsToDelete AS (
    SELECT id FROM RankedRows WHERE rn > 1
)
DELETE FROM auto_service
USING RowsToDelete
WHERE auto_service.id = RowsToDelete.id


----- Данный запрос проверяет наличие пустых строк в  определенном столбце

SELECT service 
FROM auto_service as2 
WHERE NULLIF(as2.service , ' ') IS NULL

----- Заполняем пустые строки в столбцах

 -- Обновление w_exp
update auto_service as1
set w_exp = as2.w_exp
from auto_service as2
where as1.w_phone = as2.w_phone and as1.w_name = as2.w_name  and as2.w_exp IS NOT null and as1.w_exp IS NULL


-- Обновление w_name
update auto_service as1
set w_name = (
select w_name 
from auto_service as as2
where as1.w_phone = as2.w_phone and as2.w_name is not null limit 1) where as1.w_name is null  


--- Обновление w_phone
update auto_service as1
set w_phone = (
select w_phone 
from auto_service as as2
where as1.w_name= as2.w_name and as2.w_phone is not null limit 1) where as1.w_phone is null


------- Обновление email(client) 
UPDATE auto_service as1
SET email = (
SELECT email
FROM auto_service as2
WHERE as1.name = as2.name AND as2.email IS NOT null LIMIT 1 ) where  email is null

--------- Обновление name(client) 
UPDATE auto_service as1
SET name = (
SELECT name
FROM auto_service as2
WHERE as2.phone = as1.phone AND as2.email = as2.email AND as2.name IS NOT null LIMIT 1 ) WHERE name IS NULL

---- Обновление phone(client) 
UPDATE auto_service as1
SET phone = (
SELECT phone
FROM auto_service as2
WHERE as2.name = as1.name AND as2.phone IS NOT null LIMIT 1 ) WHERE phone IS NULL

-------- Обновление wages(client) 
UPDATE auto_service as1
SET wages = (
SELECT wages
FROM auto_service as2
WHERE as2.w_name = as2.w_name
AND as2.wages IS NOT null LIMIT 1) WHERE as1.wages IS NULL

--------- Обновление service 
UPDATE auto_service as1
SET service = (
SELECT service
FROM auto_service as2
WHERE as2.w_name = as1.w_name
AND as2.service IS NOT null LIMIT 1) WHERE as1.service IS NULL

-------- Обновление service_addr
UPDATE auto_service as1
SET service_addr = (
SELECT service_addr
FROM auto_service as2
WHERE as2.w_name = as1.w_name
AND as2.service_addr IS NOT null LIMIT 1 ) WHERE as1.service_addr IS null

------ Обновление car 
UPDATE auto_service as1
SET car = (
SELECT car
FROM auto_service as2
WHERE as2.name = as1.name
and as2.car IS NOT null LIMIT 1) WHERE as1.car IS NULL

------- Обновление vin 
UPDATE auto_service as1
SET vin = (
SELECT vin
FROM auto_service as2
WHERE as2.name = as1.name
AND as2.vin IS NOT null LIMIT 1) WHERE as1.vin IS NULL

-------Обновление car_number 
UPDATE auto_service as1
SET car_number = (
SELECT car_number
FROM auto_service as2
WHERE as2.name = as1.name
AND as2.car_number IS NOT null LIMIT 1) WHERE as1.car_number IS null

------ Обновление color 
UPDATE auto_service  as1
SET color = (
SELECT color
FROM auto_service as2
WHERE as2.name = as1.name
AND as2.color IS NOT null LIMIT 1) WHERE as1.color IS NULL 

---------Обновление password
UPDATE auto_service as1
SET password = (
select password
FROM auto_service as2
WHERE as2.name = as1.name AND as2.password IS NOT null LIMIT 1 ) WHERE as1.password IS null 

------ Заполнили пустые строки, далее переходим к приведению таблицы к 3НФ  

--Разбиваем большую таблицу на несколько маленьких(декомпозиция)

create table car_services (
car_service_id SERIAL PRIMARY key,
car_service_name VARCHAR(100),
car_service_address VARCHAR(255) ) 


create table  clients (
client_id SERIAL PRIMARY KEY,
client_name text,
client_phone VARCHAR(20),
client_email VARCHAR(255) ,
client_password VARCHAR(255) ) 

create table workers (
worker_id SERIAL PRIMARY KEY,
worker_name VARCHAR(255) NOT NULL,
worker_experience int,
worker_phone VARCHAR(20),
worker_wages int
) 


create table cars ( 
car_id serial PRIMARY KEY,
car_model VARCHAR(100),
car_color VARCHAR(255),
car_vin VARCHAR(255), 
car_number VARCHAR(255)
)
---------  Создаем таблицу order_details и строим связи

create table order_details ( 
order_id SERIAL PRIMARY KEY,
order_date DATE NOT NULL,
client_id INT REFERENCES clients(client_id)  ON DELETE CASCADE, 
car_service_id INT REFERENCES car_services(car_service_id)  ON DELETE CASCADE, 
worker_id INT REFERENCES Workers(worker_id)  ON DELETE CASCADE,
mileage BIGINT,
card VARCHAR(255),
payment_amount NUMERIC(10, 2),
pin VARCHAR(10),
car_id INT REFERENCES cars(car_id) ON DELETE cascade 
);


-- Вносим данные в таблицы 

INSERT INTO car_services (car_service_name, car_service_address)
SELECT distinct service, service_addr 
FROM auto_service 

--- Индекс для таблицы  car_services:
 CREATE INDEX idx_car_service_id ON car_services (car_service_id) 


INSERT INTO clients (client_name, client_phone, client_email, client_password)
SELECT DISTINCT name, phone, email, password 
FROM auto_service

--- Индекс для таблицы  clients:
CREATE INDEX idx_email ON clients (client_email)  


INSERT INTO workers (worker_name, worker_experience, worker_phone, worker_wages)
SELECT DISTINCT w_name, w_exp, w_phone, wages 
FROM auto_service

--Индекс для таблицы workers: 
CREATE INDEX idx_worker_id ON workers (worker_id) 



INSERT INTO cars (car_model, car_color, car_vin, car_number)
SELECT DISTINCT car, color, vin, car_number 
FROM  auto_service 

--Индекс для таблицы cars: 
CREATE INDEX idx_car_model ON cars (car_model, car_id)






-----------Изменения в таблице workers
ALTER TABLE Workers
ADD COLUMN worker_first_name VARCHAR(100),
ADD COLUMN worker_last_name VARCHAR(100) 

UPDATE Workers
SET worker_first_name = split_part(worker_name, ' ', 1),
worker_last_name = split_part(worker_name, ' ', 2); 

ALTER TABLE Workers
DROP COLUMN  worker_name 

-------- Изменения в таблице clients 
ALTER TABLE clients 
ADD COLUMN first_name VARCHAR(100),
ADD COLUMN last_name VARCHAR(100) 

UPDATE clients
SET first_name = split_part(client_name, ' ', 1),
last_name = split_part(client_name, ' ', 2) 

ALTER TABLE clients 
DROP COLUMN client_name


------- Вносим данные в таблицу order_details

INSERT INTO order_details (order_date , client_id, car_service_id, worker_id, mileage, card, payment_amount, pin, car_id)
SELECT 
date,
(SELECT DISTINCT client_id _id FROM clients WHERE first_name = split_part(auto_service.name, ' ', 1) and last_name = split_part(auto_service.name, ' ', 2) LIMIT 1), 
(SELECT DISTINCT car_service_id FROM car_services  WHERE car_service_name = auto_service.service LIMIT 1), 
(SELECT DISTINCT worker_id FROM workers WHERE worker_first_name = split_part(auto_service.w_name, ' ', 1) and worker_last_name = split_part(auto_service.w_name, ' ', 2) LIMIT 1), 
mileage,
card,
payment,
pin,
(SELECT DISTINCT car_id FROM cars WHERE car_vin = auto_service.vin limit 1  ) 
FROM auto_service 



---- Индекс для таблицы order_details
CREATE INDEX idx_order_date ON order_details (order_date, car_service_id) 








--------------------- Задание 1.	Создать таблицу скидок и дать скидку самым частым клиентам 
 
create table discounts ( 
discount_id serial primary key,
client_id int references clients(client_id), 
 discount_percentage int  )  

----- Самые частые клиенты - это те, кто больше всего сделал заказов. Для топ-15 клиентов даём скидку 15 процентов
 with favouriteclients as ( select client_id, count(order_id) as order_quantity
from order_details 
group by client_id 
order by order_quantity desc 
limit 15 )  
INSERT INTO discounts (client_id, discount_percentage)
SELECT client_id, 15 
FROM favouriteclients  

------ Выводим имена и фамилии клиентов
select  c.client_id, c.first_name, c.last_name, discount_percentage
from clients c 
join discounts d 
using (client_id) 

------------------------------ Задание 2.Поднять зарплату трем самым результативным механикам на 10%

UPDATE workers w
SET worker_wages = worker_wages * 1.10
WHERE w.worker_id IN (
SELECT worker_id
FROM (
SELECT worker_id, COUNT(*) AS num
FROM order_details 
GROUP BY worker_id
ORDER BY num DESC
LIMIT 3
	) AS Bestworkers
)


------------------------ Задание 3.	Сделать представление для директора: филиал, 
--количество заказов за последний месяц, заработанная сумма, заработанная сумма за вычетом зарплаты

create view  branchmetrics as 
select cs.car_service_name AS branch,
COUNT(od.order_id) AS quantity,
SUM(od.payment_amount) AS total,
(SUM(od.payment_amount) - SUM(w.worker_wages)) AS NetIncome
FROM order_details od 
inner JOIN car_services cs ON od.car_service_id = cs.car_service_id
inner JOIN workers w ON od.worker_id = w.worker_id
WHERE od.order_date >= date_trunc('month', CURRENT_DATE) - interval '12 month' 
GROUP BY cs.car_service_name 


---------------- Задание 4. Сделать рейтинг самых надежных и ненадежных авто 
 
---Самые надежные модели автомобилей
SELECT 
 c.car_model,  
 COUNT(od.order_id) as num_order
FROM cars c
inner JOIN order_details od   
using (car_id)
GROUP BY c.car_model 
ORDER BY num_order     

------Самые ненадежные модели автомобилей
 SELECT 
 c.car_model,  
 COUNT(od.order_id) as num_order
FROM cars c
inner JOIN order_details od   
using (car_id)
GROUP BY c.car_model 
ORDER BY num_order desc 


-------------------------------- Задание 5.  Самый "удачный" цвет для каждой модели авто      
 
WITH Carcolors AS (
SELECT
c.car_model,
c.car_color,
COUNT(*) AS color_count,
ROW_NUMBER() OVER (PARTITION BY c.car_model ORDER BY COUNT(*) ) as rn
FROM
order_details od
inner join cars c using(car_id)
GROUP by c.car_model, c.car_color
)
select car_model, car_color, color_count
from Carcolors
WHERE rn = 1
ORDER by car_model