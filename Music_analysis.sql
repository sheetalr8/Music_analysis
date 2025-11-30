-- Q1. Who is the senior most employee based on job title?

SELECT * 
FROM employee
ORDER BY levels DESC
LIMIT 1;

-- Q2. Which countries have the most Invoices?

SELECT COUNT(invoice_id) AS invoice, billing_country AS billing_country
FROM invoice
GROUP BY billing_country
ORDER BY billing_country DESC;

-- Q3. What are top 3 values of total invoice?

SELECT *
FROM invoice
ORDER BY total DESC
LIMIT 3;

-- Q4. Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
--     Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals.

SELECT billing_city, SUM(total) AS total
FROM invoice
GROUP BY billing_city
ORDER BY total DESC
LIMIT 1;

-- Q5. Who is the best customer? The customer who has spent the most money will be declared the best customer. 
--     Write a query that returns the person who has spent the most money.
select * from customer;
SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS total
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total DESC
LIMIT 1;

-- Q6. Write a query to return the email, first name, last name, & Genre of all Rock Music listeners. Return your list ordered alphabetically by email starting with A 

SELECT DISTINCT email, first_name, last_name 
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id 
	IN (SELECT track_id 
	    FROM track
	    JOIN genre ON genre.genre_id = track.genre_id
	    WHERE genre.name LIKE 'Rock')
ORDER BY email;

-- Q7. Let's invite the artists who have written the most rock music in our dataset. 
--     Write a query that returns the Artist name and total track count of the top 10 rock bands.

SELECT artist.artist_id, artist.name, COUNT(track.track_id) AS num_of_songs
FROM artist
JOIN album ON album.artist_id = artist.artist_id
JOIN track ON track.album_id = album.album_id
WHERE genre_id 
	IN (SELECT genre_id 
	    FROM genre
	    WHERE name LIKE 'Rock')
GROUP BY artist.artist_id, artist.name
ORDER BY num_of_songs DESC
LIMIT 10;

-- Q8. Return all the track names that have a song length longer than the average song length. 
--     Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.

SELECT name, milliseconds
FROM track
WHERE milliseconds > (SELECT AVG(milliseconds) as avg_track_length
		      	FROM track)
ORDER BY milliseconds DESC;

-- Q9. Which genres generate the highest revenue?
SELECT 
  g.Name AS genre,
  SUM(il.Quantity * il.Unit_Price) AS total_revenue
FROM Invoice_Line il
JOIN Track t ON il.Track_Id = t.Track_Id
JOIN Genre g ON t.Genre_Id = g.Genre_Id
GROUP BY g.Genre_Id, g.Name
ORDER BY total_revenue DESC;

-- Q10. How does revenue by genre vary by country?
SELECT 
  c.Country,
  g.Name AS genre,
  SUM(il.Quantity * il.Unit_Price) AS revenue
FROM Customer c
JOIN Invoice i ON c.Customer_Id = i.Customer_Id
JOIN Invoice_Line il ON i.Invoice_Id = il.Invoice_Id
JOIN Track t ON il.Track_Id = t.Track_Id
JOIN Genre g ON t.Genre_Id = g.Genre_Id
GROUP BY c.Country, g.Genre_Id, g.Name
ORDER BY c.Country, revenue DESC;

-- Q11. Which artists are the biggest earners?
SELECT
  ar.Name AS artist,
  SUM(il.Quantity * il.Unit_Price) AS revenue
FROM Artist ar
JOIN Album al ON ar.Artist_Id = al.Artist_Id
JOIN Track t ON al.Album_Id = t.Album_Id
JOIN Invoice_Line il ON t.Track_Id = il.Track_Id
GROUP BY ar.Artist_Id, ar.Name
ORDER BY revenue DESC
LIMIT 10;  -- or whatever “top N” you want

-- Q11. Find how much amount spent by each customer on artists. Write a query to return the customer name, artist name, and total spent.

SELECT 
    c.first_name AS customer_name,
    ar.name AS artist_name,
    SUM(il.unit_price * il.quantity) AS total_spent
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album al ON al.album_id = t.album_id
JOIN artist ar ON ar.artist_id = al.artist_id
GROUP BY c.first_name, ar.name
order by total_spent desc;


-- Q12. We want to find out the most popular music Genre for each country. 
--      We determine the most popular genre as the genre with the highest amount of purchases. 
--      Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres.

WITH popular_genre AS (
    SELECT 
        c.country,
        g.name AS genre_name,
        COUNT(il.quantity) AS purchases,
        RANK() OVER (
            PARTITION BY c.country 
            ORDER BY COUNT(il.quantity) DESC
        ) AS rank_genre
    FROM invoice_line il
    JOIN invoice i ON il.invoice_id = i.invoice_id
    JOIN customer c ON i.customer_id = c.customer_id
    JOIN track t ON il.track_id = t.track_id
    JOIN genre g ON t.genre_id = g.genre_id
    GROUP BY c.country, g.name
)
SELECT country, genre_name, purchases
FROM popular_genre
WHERE rank_genre = 1
ORDER BY country;

-- Q13. Write a query that determines the customer that has spent the most on music for each country. Write a query that returns the country along with the top customer and how much they spent. For countries where the top amount spent is shared, provide all customers who spent this amount.

WITH customer_with_country AS
	(SELECT customer.customer_id, first_name, last_name, billing_country, SUM(total) AS total_spent,
	ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS row_num
	FROM invoice
	JOIN customer ON customer.customer_id = invoice.customer_id
	GROUP BY 1,2,3,4
	ORDER BY 4, 5 DESC)
SELECT customer_id, first_name, last_name, billing_country, total_spent
FROM customer_with_country
WHERE row_num = 1;

-- Q14. Who are the most popular artists?

SELECT COUNT(invoice_line.quantity) AS purchases, artist.name AS artist_name
FROM invoice_line 
JOIN track ON track.track_id = invoice_line.track_id
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
GROUP BY 2
ORDER BY 1 DESC;

-- Q15. Which is the most popular song?

SELECT COUNT(invoice_line.quantity) AS purchases, track.name AS song_name
FROM invoice_line 
JOIN track ON track.track_id = invoice_line.track_id
GROUP BY 2
ORDER BY 1 DESC;

-- Q16. What are the average prices of different types of music?

WITH purchases AS
	(SELECT genre.name AS genre, SUM(total) AS total_spent
	FROM invoice
	JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 1
	ORDER BY 2)
SELECT genre, CONCAT('$', ROUND(AVG(total_spent))) AS total_spent
FROM purchases
GROUP BY genre;

-- Q17. What are the most popular countries for music purchases?

SELECT COUNT(invoice_line.quantity) AS purchases, customer.country
FROM invoice_line 
JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
JOIN customer ON customer.customer_id = invoice.customer_id
GROUP BY country
ORDER BY purchases DESC;

-- Views

-- Q1 total revenue per genre
CREATE VIEW view_genre_revenue AS
SELECT
  g.Genre_Id,
  g.Name AS GenreName,
  SUM(il.Quantity * il.Unit_Price) AS TotalRevenue,
  SUM(il.Quantity) AS Total_Units
FROM Invoice_Line il
JOIN Track t ON il.Track_Id = t.Track_Id
JOIN Genre g ON t.Genre_Id = g.Genre_Id
GROUP BY g.Genre_Id, g.Name;

SELECT * FROM view_genre_revenue;
SELECT * FROM view_genre_revenue
ORDER BY TotalRevenue DESC
LIMIT 2;

-- Q2. genre revenue per country (ranked)
CREATE VIEW view_country_genre_revenue AS
SELECT
  c.Country,
  g.Genre_Id,
  g.Name AS GenreName,
  SUM(il.Quantity * il.Unit_Price) AS Revenue
FROM Customer c
JOIN Invoice i ON c.Customer_Id = i.Customer_Id
JOIN Invoice_Line il ON i.Invoice_Id = il.Invoice_Id
JOIN Track t ON il.Track_Id = t.Track_Id
JOIN Genre g ON t.Genre_Id = g.Genre_Id
GROUP BY c.Country, g.Genre_Id, g.Name;

SELECT Country, GenreName, Revenue
FROM (
  SELECT *,
    RANK() OVER (PARTITION BY Country ORDER BY Revenue DESC) AS rnk
  FROM view_country_genre_revenue
) x
WHERE rnk = 1
ORDER BY Country;


-- Q3. total spent by each customer
CREATE VIEW view_customer_spend AS
SELECT
  c.Customer_Id,
  concat(c.First_Name," ", c.Last_Name) AS CustomerName,
  c.Country,
  SUM(il.Quantity * il.Unit_Price) AS TotalSpent,
  COUNT(DISTINCT i.Invoice_Id) AS InvoiceCount
FROM Customer c
LEFT JOIN Invoice i ON c.Customer_Id = i.Customer_Id
LEFT JOIN Invoice_Line il ON i.Invoice_Id = il.Invoice_Id
GROUP BY c.Customer_Id, c.First_Name, c.Last_Name, c.Country;

SELECT * FROM view_customer_spend
WHERE TotalSpent > 20
ORDER BY TotalSpent DESC
LIMIT 20;


-- Stored Procedures

-- Q1. Revenue by Year
DELIMITER $$

CREATE PROCEDURE RevenueByYear(IN p_year INT)
BEGIN
    SELECT YEAR(i.Invoice_Date) AS Year,
           SUM(il.Unit_Price * il.Quantity) AS Revenue
    FROM Invoice i
    JOIN Invoice_Line il ON i.Invoice_Id = il.Invoice_Id
    WHERE YEAR(i.Invoice_Date) = p_year
    GROUP BY YEAR(i.Invoice_Date);
END$$

DELIMITER ;
CALL RevenueByYear(2020);


-- Q2. Get Top N Artists by Revenue
DELIMITER $$

CREATE PROCEDURE GetTopArtists(IN p_limit INT)
BEGIN
    SELECT ar.Artist_Id,
           ar.Name AS ArtistName,
           SUM(il.Quantity * il.Unit_Price) AS Revenue
    FROM Artist ar
    JOIN Album al ON ar.Artist_Id = al.Artist_Id
    JOIN Track t ON al.Album_Id = t.Album_Id
    JOIN Invoice_Line il ON t.Track_Id = il.Track_Id
    GROUP BY ar.Artist_Id, ar.Name
    ORDER BY Revenue DESC
    LIMIT p_limit;
END$$

DELIMITER ;

CALL GetTopArtists(10);



 




 