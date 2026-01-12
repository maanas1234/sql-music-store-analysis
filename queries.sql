-- =========================================================
-- BASIC DATA EXPLORATION
-- =========================================================

-- View all employees
SELECT * FROM employee;

-- 1. Who is the senior most employee based on job title?
SELECT first_name, last_name, title
FROM employee
WHERE title LIKE 'Senior%';


-- =========================================================
-- INVOICE & CUSTOMER OVERVIEW
-- =========================================================

-- View all invoices
SELECT * FROM invoice;

-- View all customers
SELECT * FROM customer;


-- =========================================================
-- SALES ANALYSIS
-- =========================================================

-- 2. Which countries have the most invoices?
SELECT COUNT(invoice_id) AS c, billing_country
FROM invoice
GROUP BY billing_country
ORDER BY c DESC;

-- 3. What are the top 3 values of total invoice?
SELECT total AS t
FROM invoice
ORDER BY t DESC
LIMIT 3;

-- 4. Which city has the best customers?
-- (City with the highest total invoice amount)
SELECT SUM(total) AS k, billing_city
FROM invoice
GROUP BY billing_city
ORDER BY k DESC
LIMIT 1;

-- 5. Who is the best customer?
-- (Customer who has spent the most money overall)
SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS k
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY k DESC
LIMIT 1;


-- =========================================================
-- REFERENCE TABLE CHECKS
-- =========================================================

-- View customer table
SELECT * FROM customer;

-- View genre table
SELECT * FROM genre;

-- View media types
SELECT * FROM media_type;

-- View artists
SELECT * FROM artist;

-- View tracks
SELECT * FROM track;


-- =========================================================
-- MUSIC & CUSTOMER BEHAVIOR ANALYSIS
-- =========================================================

-- 1. Return the email, first name, last name, & genre of all Rock music listeners
-- Ordered alphabetically by email
SELECT c.first_name, c.last_name, c.email, g.name
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN genre g ON g.genre_id = t.genre_id
WHERE g.name = 'Rock'
GROUP BY c.first_name, c.last_name, c.email, g.name
ORDER BY c.email;


-- =========================================================
-- ADDITIONAL TABLE CHECKS
-- =========================================================

-- View invoice_line table
SELECT * FROM invoice_line;

-- View invoice table again
SELECT * FROM invoice;

-- View playlist_track table
SELECT * FROM playlist_track;


-- =========================================================
-- TRACK ANALYSIS
-- =========================================================

-- 3. Return all track names that are longer than the average song length
-- Ordered by longest duration first
SELECT milliseconds, name
FROM track
WHERE milliseconds > (
    SELECT AVG(milliseconds) AS avg_milliseconds
    FROM track
)
ORDER BY milliseconds DESC;


-- =========================================================
-- CUSTOMER & ARTIST SPENDING ANALYSIS
-- =========================================================

-- 1. Find how much amount each customer has spent on each artist
SELECT c.customer_id,
       c.first_name,
       c.last_name,
       art.name,
       SUM(i.total) AS total
FROM customer c
JOIN invoice i ON i.customer_id = c.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN artist art ON art.artist_id = alb.artist_id
GROUP BY c.customer_id, c.first_name, c.last_name, art.name
ORDER BY total DESC;


-- =========================================================
-- WINDOW FUNCTION ANALYSIS
-- =========================================================

-- 2. Find the most popular music genre for each country
-- (Handles ties using DENSE_RANK)
SELECT *
FROM (
    SELECT *,
           DENSE_RANK() OVER (
               PARTITION BY billing_country
               ORDER BY total DESC
           ) AS rank
    FROM (
        SELECT i.billing_country,
               g.name,
               SUM(i.total) AS total
        FROM invoice i
        JOIN invoice_line il ON il.invoice_id = i.invoice_id
        JOIN track t ON t.track_id = il.track_id
        JOIN genre g ON g.genre_id = t.genre_id
        GROUP BY billing_country, g.name
    ) k
) x
WHERE rank = 1;


-- 3. Find the customer who has spent the most on music for each country
-- (Includes ties using DENSE_RANK)
SELECT *
FROM (
    SELECT *,
           DENSE_RANK() OVER (
               PARTITION BY billing_country
               ORDER BY total DESC
           ) AS rank
    FROM (
        SELECT c.first_name,
               c.last_name,
               SUM(i.total) AS total,
               i.billing_country
        FROM customer c
        JOIN invoice i ON i.customer_id = c.customer_id
        GROUP BY c.first_name, c.last_name, i.billing_country
    ) k
) x
WHERE rank = 1;
