Select * from Profiles
Select * from Houses
Select * from Addresses
Select * from Employment_Details
Select * from Referral
Select * from Tenancy_History

--#Q1 Write a query to get Profile ID, Full Name and Contact Number of the tenant who has stayed.
--    with us for the longest time period in the past
USE Tenant

SELECT TOP 1 p.profile_id, CONCAT(first_name,' ',last_name) AS full_name ,phone, 
DATEDIFF(DAY,TH.move_in_date,TH.move_out_date) AS MaxDuration
FROM Profiles P 
join Tenancy_History TH ON P.profile_id = TH.profile_id
ORDER BY MaxDuration DESC

--#Q2 Write a query to get the Full name, email id, phone of tenants who are married and paying.
--    rent > 9000 using subqueries
	
SELECT CONCAT(first_name,' ',last_name) AS full_name, email_id, phone
FROM Profiles 
WHERE profile_id IN
(
Select profile_id FROM Tenancy_History
WHERE marital_status = 'Y' AND rent > 9000
)


-- Q3 Write a query to display profile id, full name, phone, email id, city, house id, move_in_date , 
-- move_out date, rent, total number of referrals made, latest employer and the occupational category of 
-- all the tenants living in Bangalore or Pune in the time period of jan 2015 to jan 2016 sorted by their 
-- rent in descending order

SELECT  P.profile_id,
		CONCAT(first_name,' ',last_name) AS full_name,
		phone,
		email_id, 
		city,
		TH.house_id,
		TH.move_in_date,
		TH.move_out_date,
		TH.rent,
		(
        SELECT COUNT(*)
        FROM Referral R
        WHERE R.profile_id = P.profile_id
		) AS Total_Referrals,
		ED.latest_employer,
		ED.occupational_category
		FROM Profiles P
		JOIN 
			Tenancy_History TH ON P.profile_id = TH.profile_id
		JOIN 
			Employment_Details ED ON ED.profile_id = TH.profile_id
		WHERE
		(P.city = 'Bangalore' OR P.city = 'Pune') 
		AND TH.move_in_date >= '2015-01-01' 
		AND TH.move_out_date <= '2016-01-01'
		ORDER BY TH.rent DESC


-- Q4 Write a sql snippet to find the full_name, email_id, phone number and referral code of all
-- the tenants who have referred more than once. Also find the total bonus amount they should 
-- receive given that the bonus gets calculated only for valid referrals. 

SELECT	
	CONCAT(P.first_name,' ',P.last_name) AS full_name,
	email_id,
	phone,
	referral_code,
	COUNT(R.profile_id)	AS ReferralsMoreThan1,
	SUM(CASE WHEN R.referral_valid = 1 THEN R.referrer_bonus_amount ELSE 0 END) AS TotalReferralBonus
FROM 
	Profiles P
LEFT JOIN
	Referral R ON P.profile_id = R.profile_id
GROUP BY
	P.first_name,P.last_name,P.email_id,P.phone,P.referral_code
HAVING
	COUNT(R.profile_id) > 1


-- Q5 Write a query to find the rent generated from each city and also the total of all cities.

SELECT 
	city,
	SUM(TH.rent) AS Rent_Generated,
	SUM(SUM(TH.rent)) OVER () AS Total_Rent
FROM 
	Profiles P
JOIN 
	Tenancy_History TH ON P.profile_id = TH.profile_id
GROUP BY
	city

go
-- Q6 Create a view 'vw_tenant' find profile_id,rent,move_in_date,house_type,beds_vacant,
-- description and city of tenants who shifted on/after 30th april 2015 and are living 
-- in houses having vacant beds and its address.

CREATE VIEW
vw_tenant 
AS

SELECT 
	P.profile_id,
	TH.rent,
	TH.move_in_date,
	H.house_type,
	H.beds_vacant,
	A.description,
	A.city,
	A.name
FROM 
	Profiles P
JOIN
	Tenancy_History TH ON P.profile_id = TH.profile_id
JOIN
	Houses H ON TH.house_id = H.house_id
JOIN
	Addresses A ON H.house_id = A.house_id
WHERE
	TH.move_in_date >= '2015-04-30'
AND
	H.beds_vacant > 0


-- Q7 Write a code to extend the valid_till date for a month of tenants who have referred more
-- than one time
Begin Transaction

UPDATE Referral
	SET valid_till = DATEADD(MONTH,1,valid_till)
	WHERE profile_id IN
	(
    SELECT profile_id
    FROM Referral
    GROUP BY profile_id
    HAVING COUNT(*) > 1
	)

ROLLback


-- Q8 Write a query to get Profile ID, Full Name, Contact Number of the tenants along with 
-- a new column 'Customer Segment' wherein if the tenant pays rent greater than 10000, 
-- tenant falls in Grade A segment, if rent is between 7500 to 10000, tenant falls in 
-- Grade B else in Grade C

SELECT 
	P.profile_id,
	CONCAT(first_name,' ',last_name) AS full_name,
	phone,
	TH.rent,
	CASE
	WHEN TH.rent > 10000 THEN 'Grade A'
        WHEN Th.rent BETWEEN 7500 AND 10000 THEN 'Grade B'
        ELSE 'Grade C'
    END AS Customer_Segment
FROM 
	Profiles P
JOIN
	Tenancy_History TH ON P.profile_id = TH.profile_id
ORDER BY
	Customer_Segment


-- Q9 Write a query to get Fullname, Contact, City and House Details of the tenants who have not
--	  referred even once 

SELECT
	P.profile_id,
	CONCAT(first_name,' ',last_name) AS full_name,
	phone,
	city,
	H.house_type,
	H.furnishing_type,
	H.bhk_type,
	H.beds_vacant,
	H.bed_count,
	TH.bed_type,
	TH.rent
FROM 
	Profiles P
JOIN
	Tenancy_History TH ON P.profile_id = TH.profile_id 
JOIN
	Houses H ON TH.house_id = H.house_id
LEFT JOIN
	Referral R ON P.profile_id = R.profile_id
WHERE
	R.profile_id IS NULL


-- Q10 Write a query to get the house details of the house having highest occupancy


SELECT TOP 1 *
FROM Houses
ORDER BY (bed_count - beds_vacant) DESC