/* Which tracks appeared in the most playlists? how many playlist did they appear in? */

SELECT playlist_track.TrackId,
	   tracks.Name AS 'Track Name',
	   COUNT(tracks.TrackId) AS 'Track Playlist count'
FROM playlist_track
JOIN tracks
	ON playlist_track.trackId = tracks.TrackId
GROUP BY 1
ORDER BY 3 DESC;

/* Which track generated the most revenue? */

SELECT invoice_items.TrackId, tracks.Name AS 'Track Name',
	ROUND(SUM(invoice_items.UnitPrice), 2) AS 'Total Revenue'
FROM invoice_items
JOIN tracks
	ON invoice_items.TrackId = tracks.TrackId
GROUP BY 2
ORDER BY 3 DESC
LIMIT 5;	

/* Which genre generated the most revenue? */

SELECT genres.GenreId, 
		genres.Name, 
		ROUND(SUM(invoice_items.UnitPrice), 2) AS 'Total Revenue'
FROM invoice_items
JOIN tracks
	ON invoice_items.TrackId = tracks.TrackId
JOIN genres 
	ON genres.GenreId = tracks.GenreId 
GROUP BY 1
ORDER BY 3 DESC
LIMIT 5;

/* Which album generated the most revenue? */

SELECT 
	albums.AlbumId, 
	albums.Title, 
	ROUND(SUM(invoice_items.UnitPrice), 2) AS 'Total Revenue'
FROM invoice_items
JOIN tracks
	ON invoice_items.TrackId = tracks.TrackId
JOIN albums
	ON albums.AlbumId = tracks.AlbumId 
GROUP BY 1
ORDER BY 3 DESC
LIMIT 5;

/* Which countries have the highest sales revenue? What percent of total revenue does each country make up? */

SELECT BillingCountry, SUM(Total) AS 'Total',
       (SUM(Total) * 100 )/SUM(SUM(Total)) OVER () AS 'Percentage (%)'
FROM invoices
GROUP BY 1 
ORDER BY 2 DESC;

/* How many customers did each employee support, what is the average revenue for each sale, and what is their total sale? */

SELECT
	employees.EmployeeId,
	employees.FirstName,
	employees.LastName,
	COUNT(customers.CustomerId) AS 'Number of Customers Supported',
	ROUND(SUM(invoices.Total),2) AS 'Total Sales',
	ROUND(AVG(invoices.Total),2) AS 'Average Revenue Per Sale'
FROM employees
JOIN customers
	ON employees.EmployeeId = customers.SupportRepId
JOIN invoices
	ON invoices.CustomerId = customers.CustomerId
GROUP BY 1;

/* Do longer or shorter length albums tend to generate more revenue? */

WITH album_length AS (
    SELECT
        albums.AlbumId,
        albums.Title AS 'Album Title',
        albums.ArtistId,
        SUM(tracks.Milliseconds) AS 'Album Length (Milliseconds)',
        COUNT(tracks.TrackId) AS 'Number of Tracks'
    FROM albums
    JOIN tracks ON albums.AlbumId = tracks.AlbumId
    GROUP BY albums.AlbumId
)

SELECT
    album_length.'Album Title',
    album_length.'Album Length (Milliseconds)',
    album_length.'Number of Tracks',
    ROUND(SUM(invoice_items.UnitPrice) / COUNT(DISTINCT album_length.'Album Title'), 2) AS 'Average Revenue per Album'
FROM album_length
JOIN tracks ON album_length.AlbumId = tracks.AlbumId
JOIN invoice_items ON tracks.TrackId = invoice_items.TrackId
GROUP BY album_length.'Album Title', album_length.'Album Length (Milliseconds)'
ORDER BY 'Album Length (Milliseconds)' DESC;

/* Is the number of times a track appear in any playlist a good indicator of sales? */

WITH playlist AS (
	SELECT 
		playlist_track.TrackId,
		COUNT(DISTINCT playlist_track.PlaylistId) AS 'Number of Appearances'
	FROM playlist_track
	GROUP BY playlist_track.TrackId
)

SELECT 
	playlist.'Number of Appearances',
	ROUND(SUM(invoice_items.UnitPrice)/COUNT(DISTINCT(playlist.TrackId)),2) AS 'Average Track Revenue'
FROM playlist
JOIN invoice_items
 ON playlist.TrackId = invoice_items.TrackId 
GROUP BY 1
ORDER BY 2 DESC;

/* How much revenue is generated each year, and what is its percent change from the previous year? */

WITH revenue AS (
    SELECT 
        CAST(strftime('%Y', invoices.InvoiceDate) AS INTEGER) AS "Year",
        ROUND(SUM(invoices.Total), 2) AS "Total Revenue per Year"
    FROM invoices
    GROUP BY "Year"
)

SELECT 
    cur."Year" AS "Year",
    cur."Total Revenue per Year" AS "Total Revenue per Year",
    ROUND((cur."Total Revenue per Year" - prev."Total Revenue per Year") /
          prev."Total Revenue per Year" * 100, 2) AS "Percentage Change from Previous Year"
FROM revenue cur
LEFT JOIN revenue prev ON prev."Year" = cur."Year" - 1;
