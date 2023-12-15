create database MUSICSTORE_DATABASE;
USE MUSICSTORE_DATABASE;

-- Question Set 1 - Easy
-- Q1) Who is the senior most employee based on job title?
SELECT * FROM EMPLOYEE
ORDER BY LEVELS DESC
LIMIT 1

-- Q2) Which countries have the most Invoices?
SELECT COUNT(*) AS COUNT, BILLING_COUNTRY 
FROM INVOICE 
GROUP BY BILLING_COUNTRY 
ORDER BY COUNT DESC

-- Q3) What are top 3 values of total invoice?
SELECT TOTAL AS TOP_3_VALUES 
FROM INVOICE 
ORDER BY TOTAL DESC 
LIMIT 3 

-- Q4) Which city has the best customers? We would like to throw a promotional Music Festival in the 
--     city we made the most money. Write a query that returns one city that has the highest sum of 
--     invoice totals. Return both the city name & sum of all invoice totals.
SELECT SUM(TOTAL) AS INVOICE_TOTAL, BILLING_CITY 
FROM INVOICE 
GROUP BY BILLING_CITY
ORDER BY INVOICE_TOTAL DESC

-- Q5) Who is the best customer? The customer who has spent the most money will be declared the best customer. 
--     Write a query that returns the person who has spent the most money 
SELECT CUSTOMER.CUSTOMER_ID, CUSTOMER.FIRST_NAME, CUSTOMER.LAST_NAME, SUM(INVOICE.TOTAL) AS TOTAL
FROM CUSTOMER
JOIN INVOICE ON CUSTOMER.CUSTOMER_ID = INVOICE.CUSTOMER_ID 
GROUP BY CUSTOMER.CUSTOMER_ID
ORDER BY TOTAL DESC
LIMIT 1;

-- Question Set 2 – Moderate
-- Q1) Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
--     Return your list ordered alphabetically by email starting with A 
SELECT DISTINCT EMAIL,FIRST_NAME, LAST_NAME
FROM CUSTOMER 
JOIN INVOICE ON CUSTOMER.CUSTOMER_ID = INVOICE.CUSTOMER_ID
JOIN INVOICE_LINE ON INVOICE.INVOICE_ID = INVOICE_LINE.INVOICE_ID
WHERE TRACK_ID IN(
	SELECT TRACK_ID FROM TRACK
    JOIN GENRE ON TRACK.GENRE_ID = GENRE.GENRE_ID
    WHERE GENRE.NAME LIKE 'ROCK'
)
ORDER BY EMAIL;

-- Q2) Let's invite the artists who have written the most rock music in our dataset. Write a query that 
--     returns the Artist name and total track count of the top 10 rock bands.
SELECT artist.artist_id, artist.name, COUNT(artist.artist_id) AS NUMBER_OF_SONGS
FROM track
JOIN album2 ON album2.album_id = track.album_id
JOIN artist ON artist.artist_id = album2.artist_id
JOIN genre.name ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'ROCK'
GROUP BY artist.artist_id
ORDER BY NUMBER_OF_SONGS DESC
LIMIT 10; 

-- Q3) Return all the track names that have a song length longer than the average song length. Return the Name and 
--     Milliseconds for each track. Order by the song length with the longest songs listed first. 
SELECT NAME,milliseconds
FROM TRACK
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS AVG_TRACK_LENGHT
    FROM TRACK)
ORDER BY milliseconds DESC;

-- Question Set 3 – Advance
-- Q1) Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent.
WITH BEST_SELLING_ARTIST AS(
	SELECT ARTIST.ARTIST_ID AS ARTIST_ID, ARTIST.NAME AS ARTIST_NAME, 
    SUM(INVOICE_LINE.UNIT_PRICE * INVOICE_LINE.QUANTITY) AS TOTAL_SALES
    FROM INVOICE_LINE
    JOIN TRACK ON TRACK.TRACK_ID = INVOICE_LINE.TRACK_ID
    JOIN ALBUM2 ON ALBUM2.ALBUM_ID = TRACK.ALBUM_ID
    JOIN ARTIST ON ARTIST.ARTIST_ID = ALBUM2.ARTIST_ID
    GROUP BY 1
    ORDER BY 3 DESC
    LIMIT 1
)
SELECT C.CUSTOMER_ID, C.FIRST_NAME, C.LAST_NAME, BSA.ARTIST_NAME,
SUM(IL.UNIT_PRICE * IL.QUANTITY) AS AMOUNT_SPENT
FROM INVOICE I
JOIN CUSTOMER C ON C.CUSTOMER_ID = I.CUSTOMER_ID
JOIN INVOICE_LINE IL ON IL.INVOICE_ID = I.INVOICE_ID
JOIN TRACK T ON T.TRACK_ID = IL.TRACK_ID
JOIN ALBUM2 ALB ON ALB.ALBUM_ID = T.ALBUM_ID
JOIN BEST_SELLING_ARTIST BSA ON BSA.ARTIST_ID = ALB.ARTIST_ID
GROUP BY 1,2,3,4
ORDER BY 5 DESC; 

-- Q2) We want to find out the most popular music Genre for each country. We determine the most popular genre as the 
--     genre with the highest amount of purchases. Write a query that returns each country along with the top Genre. 
--     For countries where the maximum number of purchases is shared return all Genres.
WITH POPULAR_GENRE AS (
	SELECT COUNT(INVOICE_LINE.QUANTITY) AS PURCHASEA, CUSTOMER.COUNTRY, GENRE.NAME, GENRE.GENRE_ID,
    ROW_NUMBER() OVER(PARTITION BY CUSTOMER.COUNTRY ORDER BY COUNT(INVOICE_LINE.QUANTITY) DESC) AS ROWNO
    FROM INVOICE_LINE 
    JOIN INVOICE ON INVOICE.INVOICE_ID = INVOICE_LINE.INVOICE_ID
    JOIN CUSTOMER ON CUSTOMER.CUSTOMER_ID = INVOICE.CUSTOMER_ID
    JOIN TRACK ON TRACK.TRACK_ID = INVOICE_LINE.TRACK_ID
    JOIN GENRE ON GENRE.GENRE_ID = TRACK.GENRE_ID
    GROUP BY 2,3,4
    ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM POPULAR_GENRE WHERE ROWNO <= 1

-- OR --

WITH RECURSIVE
	SALES_PER_COUNTRY AS(
		SELECT COUNT(*) AS PURCHASES_PER_GENRE, CUSTOMER.COUNTRY, GENRE.NAME, GENRE.GENRE_ID
        FROM INVOICE_LINE 
        JOIN INVOICE ON INVOICE.INVOICE_ID = INVOICE_LINE.INVOICE_ID
        JOIN CUSTOMER ON CUSTOMER.CUSTOMER_ID = INVOICE.CUSTOMER_ID
        JOIN TRACK ON TRACK.TRACK_ID = INVOICE_LINE.TRACK_ID
        JOIN GENRE ON GENRE.GENRE_ID = TRACK.GENRE_ID
        GROUP BY 2,3,4
        ORDER BY 2
	),
    MAX_GENRE_PER_COUNTRY AS (SELECT MAX(PURCHASES_PER_GENRE) AS MAX_GENRE_NUMBER, COUNTRY
    FROM SALES_PER_COUNTRY
    GROUP BY 2
    ORDER BY 2)
SELECT SALES_PER_COUNTRY.*
FROM SALES_PER_COUNTRY
JOIN MAX_GENRE_PER_COUNTRY ON SALES_PER_COUNTRY.COUNTRY = MAX_GENRE_PER_COUNTRY.COUNTRY
WHERE SALES_PER_COUNTRY.PURCHASES_PER_GENRE = MAX_GENRE_PER_COUNTRY.MAX_GENRE_NUMBER

-- Q3) Write a query that determines the customer that has spent the most on music for each country. 
--     Write a query that returns the country along with the top customer and how much they spent. 
--     For countries where the top amount spent is shared, provide all customers who spent this amount.

WITH RECURSIVE
	CUSTOMER_WITH_COUNTRY AS(
		SELECT CUSTOMER.CUSTOMER_ID, FIRST_NAME, LAST_NAME, BILLING_COUNTRY, SUM(TOTAL) AS TOTAL_SPENDING
        FROM INVOICE
        JOIN CUSTOMER ON CUSTOMER.CUSTOMER_ID = INVOICE.CUSTOMER_ID
        GROUP BY 1,2,3,4
        ORDER BY 2,3 DESC),
	COUNTRY_MAX_SPENDING AS(
		SELECT BILLING_COUNTRY, MAX(TOTAL_SPENDING) AS MAX_SPENDING
        FROM CUSTOMER_WITH_COUNTRY
        GROUP BY BILLING_COUNTRY)
SELECT CC.BILLING_COUNTRY, CC.TOTAL_SPENDING, CC.FIRST_NAME, CC.LAST_NAME, CC.CUSTOMER_ID
FROM CUSTOMER_WITH_COUNTRY CC
JOIN COUNTRY_MAX_SPENDING MS
ON CC.BILLING_COUNTRY = MS.BILLING_COUNTRY
WHERE CC.TOTAL_SPENDING = MS.MAX_SPENDING
ORDER BY 1;

-- OR --

WITH CUSTOMER_WITH_COUNTRY AS (
		SELECT CUSTOMER.CUSTOMER_ID, FIRST_NAME, LAST_NAME, BILLING_COUNTRY, SUM(TOTAL) AS TOTAL_SPENDING,
        ROW_NUMBER() OVER(PARTITION BY BILLING_COUNTRY ORDER BY SUM(TOTAL) DESC) AS ROWNO
        FROM INVOICE
        JOIN CUSTOMER ON CUSTOMER. CUSTOMER_ID = INVOICE.CUSTOMER_ID
        GROUP BY 1,2,3,4
        ORDER BY 4 ASC, 5 DESC)
SELECT * FROM CUSTOMER_WITH_COUNTRY WHERE ROWNO <= 1