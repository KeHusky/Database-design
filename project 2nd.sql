/*Specification:
 *1. Creat Tables:
 *  - Database: Group3_Project;
 *  - Tables (include data types and primary keys): details in ER.png;
 *  - CHECK Constraints: TABLE Restaurant, TABLE Food, TABLE Order_food;
 *  - UNIQUE Constraint: TABLE Res_license;
 *  - Function (fn_total): helps sql calculate the total money in the Order Table;
 *  - Function (fn_pay_money): helps sql calculate the money actual paid in the Order Table;
 *  - Function (fn_coupon_check): helps sql check the coupon is validated in the Order Table;
 *2. FOREIGN KEY Constraint:
 *  - Foreign keys: details in ER.png;
 *3. Table-level constraint based on function
 *4. Insert Data
 *5. Create Views
 *  - delivertasknum: check the total number of tasks that each deliver delivered;
 *  - restaurantordernum: check the total number of order that the restauran had;
 *  (Details in ER.png)
 *6. Password Encryption
 *  - Encrypte Column 'password' in Table 'Customer'.
 */


USE Group3_Project;

DROP TABLE Order_food, Res_activity, Res_license, deliver_task, Deliver_license, Order_comment, Deliver, PAY, Food;
DROP TABLE [Order], Coupon, Food_category, Restaurant, customer_address, Customer;
DROP FUNCTION fn_pay_money;

-- 1. Creat Tables

CREATE FUNCTION fn_total(@order_id VARCHAR(64))
RETURNS MONEY
AS
BEGIN 
 DECLARE @total MONEY
 SELECT @total = SUM(f.sell_price * [of].amount) + o.box_cost + o.send_cost 
 FROM [Order] o 
 JOIN Order_food [of]
 ON [of].order_id = o.order_id 
 JOIN Food f
 ON f.food_id = [of].food_id 
 WHERE o.order_id  = @order_id
 GROUP BY o.box_cost ,o.send_cost 
 --SELECT @total

 RETURN @total 

END;

CREATE FUNCTION fn_pay_money(@order_id VARCHAR(64))
RETURNS MONEY
AS
BEGIN 
 DECLARE @total MONEY
 SET @total = dbo.fn_total(@order_id)
  
 DECLARE @target_a MONEY 
 SELECT @target_a = ra.target 
 FROM [Order] o
 JOIN Res_activity ra
 ON ra.res_id = o.res_id 
 WHERE o.order_id = @order_id
 --SELECT @target_a
 
 DECLARE @discount_a MONEY = 0
 IF @total > @target_a
 BEGIN 
 	SELECT @discount_a = ra.discount 
 	FROM [Order] o 
 	JOIN Res_activity ra
 	ON ra.res_id = o.res_id 
 	WHERE o.order_id = @order_id
 END
 --SELECT @discount_a
 
 DECLARE @target_c MONEY
 SELECT @target_c = c.target 
 FROM [Order] o
 JOIN Coupon c
 ON c.coupon_id = o.coupon_id 
 WHERE o.order_id = @order_id
 --SELECT @target_c
 
 DECLARE @discount_c MONEY = 0
 IF @total - @discount_a > @target_c
 BEGIN 
 	SELECT @discount_c = c.discount 
 	FROM [Order] o 
 	JOIN Coupon c
 	ON c.coupon_id = o.coupon_id 
 	WHERE o.order_id = @order_id
 END
 --SELECT @discount_c
 
 DECLARE @pay_money MONEY
 SET @pay_money = @total - @discount_a - @discount_c
 RETURN @pay_money 

END;

CREATE FUNCTION fn_coupon_check(@coupon_id VARCHAR(64)) 
RETURNS BIT
AS
BEGIN
	IF EXISTS(SELECT 'sth' FROM [Order] WHERE coupon_id = @coupon_id AND status = 'Placed')
		RETURN 0;
	RETURN 1;
END

CREATE TABLE [Order]
(
order_id VARCHAR(64) NOT NULL PRIMARY KEY,
customer_id VARCHAR(64) NOT NULL,
res_id VARCHAR(64) NOT NULL,
address_id VARCHAR(64) NOT NULL,
box_cost MONEY DEFAULT 0,
send_cost MONEY DEFAULT 0,
total AS (dbo.fn_total(order_id)),
coupon_id VARCHAR(64),
pay_money AS (dbo.fn_pay_money(order_id)),
status VARCHAR(100) NOT NULL,
create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)

CREATE TABLE Order_comment
(
comment_id VARCHAR(64) NOT NULL PRIMARY KEY,
order_id VARCHAR(64) NOT NULL,
content TEXT,
customer_id VARCHAR(64) NOT NULL
);

CREATE TABLE Pay
(
payment_id VARCHAR(64) NOT NULL PRIMARY KEY,
pay_method VARCHAR(100) NOT NULL,
order_id VARCHAR(64) NOT NULL,
deal_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
status VARCHAR(100) NOT NULL
);

CREATE TABLE Customer
(
customer_id VARCHAR(64) NOT NULL PRIMARY KEY,
username VARCHAR(100) NOT NULL,
firstname VARCHAR(100) NOT NULL,
lastname VARCHAR(100) NOT NULL,
mobile VARCHAR(100) NOT NULL,
password VARCHAR(100) NOT NULL,
email VARCHAR(100) NOT NULL
);

CREATE TABLE Restaurant
(
res_id VARCHAR(64) NOT NULL PRIMARY KEY,
res_name VARCHAR(100) NOT NULL,
res_mobile VARCHAR(100) NOT NULL,
res_password VARCHAR(100) NOT NULL,
res_email VARCHAR(100) NOT NULL,
tag VARCHAR(100),
open_time TIME NOT NULL,
close_time TIME NOT NULL,
country VARCHAR(100) NOT NULL,
state VARCHAR(100) NOT NULL,
city VARCHAR(100) NOT NULL,
street VARCHAR(100) NOT NULL,
zipcode VARCHAR(100) NOT NULL,
notice VARCHAR(100),
rating DECIMAL CHECK (rating > 0 AND rating <= 5),
min_cost MONEY DEFAULT 0,
);
 
CREATE TABLE Res_activity
(
activity_id VARCHAR(64) NOT NULL PRIMARY KEY,
res_id VARCHAR(64) NOT NULL,
target MONEY DEFAULT 0,
discount MONEY DEFAULT 0,
start_time DATETIME NOT NULL,
end_time DATETIME NOT NULL
);
 
CREATE TABLE Res_license
(
license_id VARCHAR(64) NOT NULL PRIMARY KEY,
res_id VARCHAR(64) NOT NULL,
id_name VARCHAR(100) NOT NULL,
id_num VARCHAR(100) NOT NULL UNIQUE,
business_name VARCHAR(100) NOT NULL,
state VARCHAR(100) NOT NULL,
city VARCHAR(100) NOT NULL,
street VARCHAR(100) NOT NULL,
zipcode VARCHAR(100) NOT NULL,
business_begin_time DATE NOT NULL,
business_end_time DATE NOT NULL
);
 
CREATE TABLE Coupon
(
coupon_id VARCHAR(64) NOT NULL PRIMARY KEY,
customer_id VARCHAR(64) NOT NULL,
target MONEY DEFAULT 0,
discount MONEY DEFAULT 0,
end_time DATETIME NOT NULL
);

CREATE TABLE Customer_address
(
address_id VARCHAR(64) NOT NULL PRIMARY KEY,
customer_id VARCHAR(64) NOT NULL,
country VARCHAR(100) NOT NULL,
state VARCHAR(100) NOT NULL,
city VARCHAR(100) NOT NULL,
street VARCHAR(100) NOT NULL,
apt VARCHAR(100) NOT NULL,
zipcode VARCHAR(64) NOT NULL,
label VARCHAR(100),
receiver_tel VARCHAR(100) NOT NULL,
receiver_name VARCHAR(100) NOT NULL
);

CREATE TABLE Deliver_task
(
task_id VARCHAR(64) NOT NULL PRIMARY KEY,
order_id VARCHAR(64) NOT NULL,
deliver_id VARCHAR(64) NOT NULL,
status VARCHAR(100) NOT NULL,
start_time datetime default current_timestamp
);

CREATE TABLE Deliver
(
deliver_id VARCHAR(64) NOT NULL PRIMARY KEY,
deliver_firstname VARCHAR(100) NOT NULL,
deliver_lastname VARCHAR(100) NOT NULL,
mobile VARCHAR(100) NOT NULL,
password VARCHAR(100) NOT NULL
);

CREATE TABLE Deliver_license
(
license_id VARCHAR(64) NOT NULL PRIMARY KEY,
license_number VARCHAR(100)  NOT NULL,
deliver_id VARCHAR(64) NOT NULL ,
start_time VARCHAR(100)  NOT NULL,
end_time VARCHAR(100) NOT NULL
);

CREATE TABLE Food
(
food_id VARCHAR(64) NOT NULL PRIMARY KEY,
food_cat_id VARCHAR(64) NOT NULL,
title VARCHAR(100) NOT NULL,
description TEXT,
origin_price MONEY,
sell_price MONEY NOT NULL,
total_sales INT NOT NULL CHECK (total_sales >= 0),
month_sales INT NOT NULL CHECK (month_sales >= 0),
rating DECIMAL CHECK (rating > 0 AND rating <= 5),
status VARCHAR(100)
);

CREATE TABLE Food_category
(
food_cat_id VARCHAR(64) NOT NULL PRIMARY KEY,
res_id VARCHAR(64) NOT NULL,
name VARCHAR(100) NOT NULL
);

CREATE TABLE Order_food
(
order_id VARCHAR(64) NOT NULL,
food_id VARCHAR(64) NOT NULL,
amount INT NOT NULL CHECK (amount >= 0)
);

-- 2. FOREIGN KEY Constraint
ALTER TABLE [Order] ADD 
CONSTRAINT FK1_O FOREIGN KEY(customer_id) REFERENCES Customer(customer_id),
CONSTRAINT FK2_O FOREIGN KEY(res_id) REFERENCES Restaurant(res_id),
CONSTRAINT FK3_O FOREIGN KEY(address_id) REFERENCES Customer_address(address_id),
CONSTRAINT FK4_O FOREIGN KEY(coupon_id) REFERENCES Coupon(coupon_id);

ALTER TABLE Order_comment ADD 
CONSTRAINT FK1_OC FOREIGN KEY(order_id) REFERENCES [Order](order_id),
CONSTRAINT FK2_OC FOREIGN KEY(customer_id) REFERENCES Customer(customer_id);

ALTER TABLE Deliver_task ADD 
CONSTRAINT FK_orderID FOREIGN KEY(order_id) REFERENCES [Order](order_id),
CONSTRAINT FK_deliverID FOREIGN KEY(deliver_id) REFERENCES Deliver(deliver_id);

ALTER TABLE Order_food ADD 
CONSTRAINT FK_OID FOREIGN KEY(order_id) REFERENCES [Order](order_id),
CONSTRAINT FK_FID FOREIGN KEY(food_id) REFERENCES Food(food_id);

ALTER TABLE Pay ADD CONSTRAINT FK_P FOREIGN KEY(order_id) REFERENCES [Order](order_id);

ALTER TABLE Res_activity ADD CONSTRAINT FK_RaR FOREIGN KEY (res_id) REFERENCES Restaurant(res_id);

ALTER TABLE Res_license ADD CONSTRAINT FK_RlR FOREIGN KEY (res_id) REFERENCES Restaurant(res_id);

ALTER TABLE Coupon ADD CONSTRAINT FKCR FOREIGN KEY (customer_id) REFERENCES Customer(customer_id);

ALTER TABLE Customer_address ADD CONSTRAINT FK_CustomerID FOREIGN KEY(customer_id) REFERENCES Customer(customer_id);
 
ALTER TABLE Food_category ADD CONSTRAINT FK_FC_RID FOREIGN KEY(res_id) REFERENCES Restaurant(res_id)
 
ALTER TABLE Food ADD CONSTRAINT FK_food_cat_id FOREIGN KEY(food_cat_id) REFERENCES Food_category(food_cat_id);

ALTER TABLE Deliver_license ADD CONSTRAINT FK_DLD FOREIGN KEY(deliver_id) REFERENCES Deliver(deliver_id);

-- 3. Table-level constraint based on function
ALTER TABLE [Order] ADD CONSTRAINT coupon_check CHECK (dbo.fn_coupon_check(coupon_id) = 1)

-- 4. Insert Data
INSERT Restaurant VALUES 
('R001', 'RA', '(857)123-4560', '000000', 'r0@gmail.com', 'Chinese', '7:00:00', '23:00:00', 'US', 'MA', 'Malden', '100 Exchange St', '02148', '', 5.0, 10.00),
('R002', 'RB', '(857)123-4561', '111111', 'r1@gmail.com', 'American', '9:30:00', '21:00:00', 'US', 'MA', 'Boston', '360 Huntington Ave', '02115', '', 4.5, 10.00),
('R003', 'RC', '(857)123-4562', '222222', 'r2@gmail.com', 'Mexican', '9:30:00', '22:30:00', 'US', 'MA', 'Medford', '499 Riverside Ave', '02155', '', 4.5, 10.00),
('R004', 'RD', '(857)123-4563', '333333', 'r3@gmail.com', 'Thai', '8:00:00', '23:00:00', 'US', 'MA', 'Boston', '359 Huntington Ave', '02115', '', 3.8, 10.00),
('R005', 'RE', '(857)123-4564', '444444', 'r4@gmail.com', 'Italian', '10:00:00', '20:00:00', 'US', 'MA', 'Boston', '358 Huntington Ave', '02115', '', 4.2, 10.00),
('R006', 'RF', '(857)123-4565', '555555', 'r5@gmail.com', 'Korean', '8:00:00', '22:00:00', 'US', 'MA', 'Boston', '357 Huntington Ave', '02115', '', 5.0, 10.00),
('R007', 'RG', '(857)123-4566', '666666', 'r6@gmail.com', 'Japanese', '9:00:00', '22:00:00', 'US', 'MA', 'Boston', '356 Huntington Ave', '02115', '', 3.9, 10.00),
('R008', 'RH', '(857)123-4567', '777777', 'r7@gmail.com', 'Vietnamese', '9:30:00', '22:00:00', 'US', 'MA', 'Boston', '355 Huntington Ave', '02115', '', 4.1, 10.00),
('R009', 'RI', '(857)123-4568', '888888', 'r8@gmail.com', 'Vegetarian', '9:00:00', '22:30:00', 'US', 'MA', 'Boston', '361 Huntington Ave', '02115', '', 4.0, 10.00),
('R010', 'RJ', '(857)123-4569', '999999', 'r9@gmail.com', 'Drink', '9:00:00', '23:00:00', 'US', 'MA', 'Boston', '361 Huntington Ave', '02115', '', 3.7, 10.00);
                        
INSERT Res_license VALUES 
('RL001', 'R001', 'Lily', '010101', 'RA', 'MA', 'Malden', '100 Exchange St', '02148', '2007-08-06', '2017-08-06'),
('RL002', 'R002', 'Amy', '101010', 'RB', 'MA', 'Boston', '360 Huntington Ave', '02115', '2008-06-06', '2018-06-06'),
('RL003', 'R003', 'Linda', '232323', 'RC', 'MA', 'Medford', '499 Riverside Ave', '02155', '2006-06-09', '2016-06-09'),
('RL004', 'R004', 'Linda', '323232', 'RD', 'MA', 'Boston', '359 Huntington Ave', '02115', '2009-09-06', '2019-09-06'),
('RL005', 'R005', 'Bob', '454545', 'RE', 'MA', 'Boston', '358 Huntington Ave', '02115', '2007-06-06', '2017-06-06'),
('RL006', 'R006', 'Jack', '545454', 'RF', 'MA', 'Boston', '357 Huntington Ave', '02115', '2010-10-04', '2020-10-04'),
('RL007', 'R007', 'Sam', '676767', 'RG', 'MA', 'Boston', '356 Huntington Ave', '02115', '2017-05-18', '2027-05-18'),
('RL008', 'R008', 'John', '767676', 'RH', 'MA', 'Boston', '355 Huntington Ave', '02115', '2019-02-01', '2027-05-18'),
('RL009', 'R009', 'Mary', '898989', 'RI', 'MA', 'Boston', '361 Huntington Ave', '02115', '2012-09-09', '2022-09-09'),
('RL010', 'R010', 'Mandy', '989898', 'RJ', 'MA', 'Boston', '361 Huntington Ave', '02115', '2015-08-26', '2025-08-26');
 
INSERT Res_activity VALUES 
('RA001', 'R001', 10.00, 1.00, '2020-04-01 00:00:00', '2020-05-01 23:59:59'),
('RA002', 'R002', 10.00, 1.00, '2020-04-02 00:00:00', '2020-06-01 23:59:59'),
('RA003', 'R008', 10.00, 0.50, '2020-04-03 00:00:00', '2020-05-15 23:59:59'),
('RA004', 'R009', 15.00, 3.00, '2020-04-04 00:00:00', '2020-07-01 23:59:59'),
('RA005', 'R010', 15.00, 6.00, '2020-04-05 00:00:00', '2020-08-01 23:59:59'),
('RA006', 'R006', 10.00, 2.00, '2020-04-06 00:00:00', '2020-07-04 23:59:59'),
('RA007', 'R007', 15.00, 4.00, '2020-04-01 00:00:00', '2020-07-01 23:59:59'),
('RA008', 'R008', 30.00, 2.00, '2020-04-02 00:00:00', '2020-05-01 23:59:59'),
('RA009', 'R009', 35.00, 9.00, '2020-04-03 00:00:00', '2020-06-01 23:59:59'),
('RA010', 'R010', 20.00, 8.00, '2020-04-01 00:00:00', '2020-05-15 23:59:59');

INSERT Customer VALUES 
('CT001','a','a','a','a','a','a'),
('CT002','b','b','b','b','b','b'),
('CT003','c','c','c','c','c','c'),
('CT004','d','d','d','d','d','d'),
('CT005','e','e','e','e','e','e'),
('CT006','f','f','f','f','f','f'),
('CT007','g','g','g','g','g','g'),
('CT008','h','h','h','h','h','h'),
('CT009','i','i','i','i','i','i'),
('CT010','j','j','j','j','j','j');

INSERT Customer_address VALUES
('AD001','CT001','USA','MA','Boston','ruggles','1616','02120','home','6178113421','TOM'),
('AD002','CT001','USA','MA','Boston','brooklin','72','02125','office','6178113421','TOM'),
('AD003','CT001','USA','MA','Boston','malden','36','02132','school','6178113421','TOM'),
('AD004','CT002','USA','MA','Boston','roxbury','45','02176','home','6178191321','JANE'),
('AD005','CT002','USA','MA','Boston','ruggles','31','02154','parenthome','6178191321','JANE'),
('AD006','CT003','USA','MA','Boston','alington','11','02123','home','6178151429','JOHN'),
('AD007','CT004','USA','MA','Boston','malden','5','02154','home','6174525124','JAMES'),
('AD008','CT004','USA','MA','Boston','ruggles','88','02113','office','6174525124','JAMES'),
('AD009','CT004','USA','MA','Boston','roxbury','16','02152','school','6174525124','JAMES'),
('AD010','CT004','USA','MA','Boston','ruggles','63','02114','home','6174525124','JAMES');

INSERT Deliver VALUES
('DE001','TOM','Davi','6178236798','000000'),
('DE002','JACK','Williams','6171525325','111111'),
('DE003','KOBE','Smith','6171576582','222222'),
('DE004','RYAN','Wilson','6177686383','333333'),
('DE005','TOMMY','Miller','6176938644','444444'),
('DE006','WENDY','Jones','6173425223','555555'),
('DE007','JAMES','Brown','6171575986','666666'),
('DE008','THOMAS','ALEX','6179864480','777777'),
('DE009','LAVIN','STARK','6178649542','888888'),
('DE010','HARDEN','JAMES','6171126940','999999');

INSERT Deliver_license VALUES
('DL001','000','de001','2015-12-15 00:00:00','2015-12-15 23:59:59'),
('DL002','111','de002','2016-10-08 00:00:00','2026-10-08 23:59:59'),
('DL003','222','de003','2016-02-01 00:00:00','2026-02-01 23:59:59'),
('DL004','333','de004','2015-01-05 00:00:00','2025-01-05 23:59:59'),
('DL005','444','de005','2017-08-23 00:00:00','2027-08-23 23:59:59'),
('DL006','555','de006','2018-07-06 00:00:00','2028-07-06 23:59:59'),
('DL007','666','de007','2017-06-24 00:00:00','2027-06-24 23:59:59'),
('DL008','777','de008','2018-03-18 00:00:00','2028-03-18 23:59:59'),
('DL009','888','de009','2016-08-22 00:00:00','2026-08-22 23:59:59'),
('DL010','999','de010','2019-11-12 00:00:00','2029-11-12 23:59:59');

INSERT Coupon VALUES 
('CP001', 'CT001', 10.00, 2.00, '2020-05-01 23:59:59'),
('CP002', 'CT001', 10.00, 1.00, '2020-06-01 23:59:59'),
('CP003', 'CT003', 10.00, 0.50, '2020-05-15 23:59:59'),
('CP004', 'CT004', 15.00, 8.00, '2020-07-01 23:59:59'),
('CP005', 'CT005', 15.00, 6.00, '2020-08-01 23:59:59'),
('CP006', 'CT006', 25.00, 12.00, '2020-07-04 23:59:59'),
('CP007', 'CT007', 25.00, 4.00, '2020-07-01 23:59:59'),
('CP008', 'CT001', 30.00, 12.00, '2020-05-01 23:59:59'),
('CP009', 'CT002', 35.00, 13.00, '2020-06-01 23:59:59'),
('CP010', 'CT003', 20.00, 2.00, '2020-05-15 23:59:59');

INSERT INTO [Order](order_id,customer_id,res_id,address_id,box_cost,send_cost,coupon_id,status) VALUES
('O001','CT001','R002','AD001',2.00,5.00,'CP001','Order Placed'),
('O002','CT002','R010','AD004',5.00,8.00,'CP009','Order Placed'),
('O003','CT001','R010','AD001',3.00,8.00,'CP002','Order Placed'),
('O004','CT002','R010','AD004',4.00,8.00,NULL,'Order Placed'),
('O005','CT002','R002','AD005',2.00,5.00,NULL,'Order Placed'),
('O006','CT003','R002','AD006',2.00,5.00,'CP003','Order Placed'),
('O007','CT004','R010','AD007',8.00,8.00,'CP004','Order Placed'),
('O008','CT004','R010','AD008',9.00,8.00,NULL,'Order Placed'),
('O009','CT001','R010','AD002',8.00,8.00,'CP008','Order Placed'),
('O010','CT001','R002','AD003',2.00,5.00,NULL,'Order Placed');

INSERT Deliver_task (task_id,order_id,deliver_id,status) VALUES
('TA001','O001','DE001','delivering'),
('TA002','O002','DE001','waiting for deliver'),
('TA003','O003','DE002','delivered'),
('TA004','O004','DE002','delivered'),
('TA005','O006','DE002','develivering'),
('TA006','O007','DE002','delivered'),
('TA007','O005','DE003','delivered'),
('TA008','O009','DE003','waiting for deliver'),
('TA009','O008','DE004','delivered'),
('TA010','O010','DE004','delivered');

INSERT [Order_comment](comment_id ,order_id  ,content  ,customer_id ) VALUES 
('CM001','O001','a','CT001'),
('CM002','O002','b','CT002'),
('CM003','O003','c','CT001'),
('CM004','O004','d','CT002'),
('CM005','O005','e','CT002'),
('CM006','O006','f','CT003'),
('CM007','O007','g','CT004'),
('CM008','O008','h','CT004'),
('CM009','O009','i','CT001'),
('CM010','O010','j','CT001');

INSERT Pay(payment_id ,pay_method  ,order_id  ,status) VALUES 
('P001','a','O001','SUCESSFUL'),
('P002','b','O002','SUCESSFUL'),
('P003','c','O003','SUCESSFUL'),
('P004','d','O004','SUCESSFUL'),
('P005','e','O005','SUCESSFUL'),
('P006','f','O006','SUCESSFUL'),
('P007','g','O007','SUCESSFUL'),
('P008','h','O008','SUCESSFUL'),
('P009','i','O009','SUCESSFUL'),
('P010','j','O010','SUCESSFUL');

INSERT INTO Food_category(food_cat_id,res_id,name) VALUES
('FC001','R002','fast food'),
('FC002','R002','coffee series'),
('FC003','R002','tenders'),
('FC004','R001','si-chuan food'),
('FC005','R001','beijing food'),
('FC006','R001','hot pot'),
('FC007','R001','milk tea'),
('FC008','R010','coffee'),
('FC009','R010','green tea'),
('FC010','R010','vita juice');
 
INSERT INTO Food (food_id,food_cat_id,title,description,origin_price,sell_price,total_sales,month_sales,rating,status) VALUES
('F001','FC001','Cheese Burger','a burger with cheese and beef',5.00,5.00,1000,100,4.1,'sold out'),
 ('F002','FC001','Double Cheese Burger','a burger with extra cheese and beef',6.00,6.00,800,90,4.5,'sold out'),
('F003','FC001','6 Nuggets','a small box of nuggets',2.00,2.00,1100,640,4.6,'available'),
('F004','FC001','12 Nuggets','a large box of nuggets',4.00,4.00,1500,300,4.8,'available'),
('F005','FC001','Fries(small)','a small box of fries',1.00,1.00,2900,1300,4.2,'available'),
('F006','FC001','Fries(large)','a large box of fries',2.50,2.50,2700,1200,4.4,'not much left'),
('F007','FC008','American Coffee','American style coffee',2.80,2.80,3400,1800,4.7,'available'),
('F008','FC008','Espresso','Italian style coffee',2.80,2.80,3100,1600,4.9,'available'),
('F009','FC003','6 Chicken Tenders','a small box of chicken tenders',8.00,12.00,1400,350,3.3,'available'),
('F010','FC003','12 Chicken Tenders','a small box of chicken tenders',14.00,23.00,1100,250,3.8,'not much left');

INSERT INTO Order_food VALUES
('O001','F001',2),
('O001','F002',1),
('O002','F008',10),
('O003','F008',5),
('O004','F008',7),
('O005','F002',6),
('O006','F002',12),
('O007','F007',15),
('O008','F007',18),
('O009','F007',15),
('O009','F008',4),
('O010','F001',3);

-- 5. Create Views
CREATE VIEW delivertasknum AS
SELECT d.deliver_firstname, d.deliver_lastname , count(dt.task_id) totalnumber
FROM Deliver d
INNER JOIN deliver_task dt
ON d.deliver_id = dt.deliver_id
GROUP BY d.deliver_firstname, d.deliver_lastname ;

CREATE VIEW restaurantordernum AS
SELECT r.res_name,count(o.order_id) totalnumber
FROM Restaurant r
INNER JOIN [dbo].[Order] o
ON r.res_id = o.res_id
GROUP BY r.res_name ;

-- 6. Password Encryption
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Password-1';

CREATE CERTIFICATE SelfSignedCertificate WITH SUBJECT = 'Password Encryption'; 

CREATE SYMMETRIC KEY SQLSymmetricKey WITH ALGORITHM = AES_128 ENCRYPTION BY CERTIFICATE SelfSignedCertificate;

ALTER TABLE Customer ADD EncryptedPassword varbinary(MAX) NULL;

OPEN SYMMETRIC KEY SQLSymmetricKey DECRYPTION BY CERTIFICATE SelfSignedCertificate;

UPDATE Customer
SET [EncryptedPassword] = EncryptByKey(Key_GUID('SQLSymmetricKey'), password);  

SELECT EncryptedPassword, CONVERT(varchar, DecryptByKey(EncryptedPassword)) AS 'DecryptedPassword'  
FROM Customer;  

CLOSE SYMMETRIC KEY SQLSymmetricKey;
