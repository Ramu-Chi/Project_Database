-- Create Profile (buyer)
CREATE OR REPLACE FUNCTION create_profile(
	IN first_name_in VARCHAR(20),
	IN last_name_in VARCHAR(20),
	IN username_in VARCHAR(30),
	IN password_in VARCHAR(30),
	IN age_in INT,
	IN email_in VARCHAR(30)
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$ 
DECLARE
	user_id INT;
BEGIN
	INSERT INTO buyers (first_name, last_name, username, password, age, email) 
		VALUES (first_name_in, last_name_in, username_in, password_in, age_in, email_in) 
		RETURNING buyer_id INTO user_id;

	RETURN FORMAT('User ID: %s', user_id);
	EXCEPTION
		WHEN unique_violation THEN
            RETURN 'duplicated username';
END;
$$;


-- Login (buyer)
CREATE OR REPLACE FUNCTION login (
    IN username_in text,
    IN password_in text
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    user_id_out INT;
BEGIN
    SELECT buyer_id INTO user_id_out FROM buyers WHERE username = username_in AND password = password_in;
    IF FOUND THEN
      RETURN user_id_out;
    ELSE 
      RETURN -1;
    END IF;
END;
$$;


-- Search Service By Category (buyer)
CREATE OR REPLACE FUNCTION search_service_by_category (
    IN limit_size_in int,
    IN category_name_in character varying(30)
)
RETURNS SETOF services
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
		SELECT * FROM services WHERE category_name = category_name_in LIMIT limit_size_in;
END;
$$;


-- Search Service By Title (buyer)
CREATE OR REPLACE FUNCTION search_service_by_title(
	IN limit_size_in INT, 
	IN title_buffer_in TEXT
)
RETURNS SETOF services
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
		SELECT *
		FROM services 
		WHERE service_title LIKE '%' || title_buffer_in || '%'
		LIMIT limit_size_in;
END;
$$;


-- Search Service By Tags (buyer)
CREATE OR REPLACE FUNCTION search_service_by_tags(
	IN limit_size_in INT, 
	IN search_buffer_in TEXT
)
RETURNS SETOF services
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
		SELECT *
		FROM services
		WHERE service_id IN (
			SELECT service_id
			FROM tags
			WHERE LOWER(search_buffer_in) LIKE '%' || LOWER(tag) || '%'
			GROUP BY service_id
			ORDER BY COUNT(tag) DESC
			LIMIT limit_size_in
		);
END;
$$;


-- Show Service Details (buyer)
CREATE OR REPLACE FUNCTION show_service_details(service_id_in integer)
RETURNS table(
	service_id int,
	service_title character varying(90), 
	username character varying(30), 
	cost numeric(5),
	description character varying(1200)
)
LANGUAGE plpgsql
AS $$
BEGIN 
	RETURN QUERY 
		SELECT s1.service_id, s1.service_title, b.username, s1.cost, s1.description
		FROM buyers as b, services as s1 
			inner join sellers as s2 using(seller_id)
		WHERE s1.service_id = service_id_in AND b.buyer_id = s2.seller_id;
END;
$$;


-- Show Service's Options (buyer)
CREATE OR REPLACE FUNCTION show_service_options(IN service_id_in int)
RETURNS TABLE(
	"Option ID" int,
	"Option Details" character varying(80),
	"Option Cost" numeric(5)
)
LANGUAGE plpgsql
AS $$
BEGIN 
	RETURN QUERY 
		SELECT option_id, option_detail, option_cost
		FROM extra_options
	 	WHERE SERVICE_ID = service_id_in;
END;
$$;


-- Show Seller's Profile (buyer)
CREATE OR REPLACE FUNCTION show_seller_profile(seller_id_in integer)
RETURNS table(first_name character varying(20), last_name character varying(20), 
			  username character varying(30), age int, email character varying(30), skill_name text)
LANGUAGE plpgsql
AS $$
BEGIN 
	RETURN QUERY 
		SELECT b.first_name, b.last_name, b.username, b.age, b.email, string_agg(sk.skill_name, ', ') 
		FROM buyers as b, seller_skill as sk
		WHERE b.buyer_id = seller_id_in AND sk.seller_id = seller_id_in
		GROUP BY b.buyer_id;
END;
$$;


-- Buy Service (buyer)
CREATE OR REPLACE FUNCTION buy_service(
	IN buyer_id_in INT, 
	IN service_id_in INT, 
	IN quantity_in INT, 
	VARIADIC option_id_arr_in INT[] DEFAULT NULL
)
RETURNS TABLE(
	"Buy ID" INT,
	"Service Title" VARCHAR(90), 
	"Quantity" INT, 
	"Options" TEXT,
	"Total Cost" NUMERIC(5, 0)
)
LANGUAGE plpgsql
AS $$
DECLARE
	i INT;
	buy_id_out INT;
	options_out TEXT;
	total_cost_out NUMERIC(5, 0);
BEGIN
	INSERT INTO buy (buyer_id, service_id, status, quantity) 
		VALUES (buyer_id_in, service_id_in, 'on', quantity_in) RETURNING buy_id INTO buy_id_out;
		
	INSERT INTO buy_option 
		SELECT buy_id_out, eo.option_id, service_id_in
		FROM extra_options eo
		WHERE eo.service_id = service_id_in AND eo.option_id = ANY (option_id_arr_in);
	
	SELECT string_agg(option_detail, ', '), sum(option_cost), eo.service_id 
		INTO options_out, total_cost_out
	FROM extra_options eo
	WHERE eo.service_id = service_id_in AND eo.option_id = ANY (option_id_arr_in)
	GROUP BY eo.service_id;
	
	IF total_cost_out IS NULL THEN 
		total_cost_out := 0;
	END IF;
		
	RETURN QUERY
		SELECT buy_id_out, s.service_title, quantity_in AS "Quantity", options_out AS "Options", quantity_in * (total_cost_out + s.cost) AS "Total Cost"
		FROM services s
		WHERE s.service_id = service_id_in;
END;
$$;


-- Edit User Profile (buyer) 
CREATE OR REPLACE FUNCTION edit_user_profile(
	IN buyer_id_in INT,
	IN first_name_in VARCHAR(20),
	IN last_name_in VARCHAR(20),
	IN age_in INT,
	IN email_in VARCHAR(30)
)
RETURNS SETOF Buyers
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
		UPDATE Buyers
		SET first_name = first_name_in, last_name = last_name_in, age = age_in, email = email_in
		WHERE buyer_id = buyer_id_in RETURNING Buyers.*;
END;
$$;


-- Register Selling (buyer)
CREATE OR REPLACE FUNCTION register_selling(IN buyer_id_in INT)
RETURNS TEXT 
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO sellers VALUES ($1);
	RETURN FORMAT('Seller Registered');
	EXCEPTION
		WHEN unique_violation THEN
			RETURN 'Cannot register more than once';
END;
$$;


-- Add Seller Skills (seller)
CREATE OR REPLACE FUNCTION add_seller_skills(
	IN seller_id_in INT,
	VARIADIC skills_in character varying(40)[]
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN 
	IF NOT EXISTS (SELECT * FROM sellers WHERE seller_id = seller_id_in) THEN
		RETURN;
	END IF;
	
	INSERT INTO seller_skill
		SELECT seller_id_in, s.skill_name
		FROM skills AS s
		WHERE s.skill_name = ANY (skills_in);
END;
$$;


-- Delete Seller Skills (seller)
CREATE OR REPLACE FUNCTION delete_seller_skills(
	IN seller_id_in INT,
	VARIADIC skills_in character varying(40)[]
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN 
	DELETE FROM seller_skill
	WHERE seller_id = seller_id_in AND skill_name = ANY (skills_in);
END;
$$;


-- Add a service (seller)
CREATE OR REPLACE FUNCTION add_service(
	IN service_title_in character varying(90),
	IN seller_id_in int, 
	IN category_name_in character varying(30),
	IN cost_in numeric(5),
	IN description_in character varying(1200),
	VARIADIC tags character varying(30)[] default NULL
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE 
	tag_name character varying(30);
	service_id_out INT;
BEGIN 
	INSERT INTO services(service_title, seller_id, category_name, cost, description, create_date)
	VALUES (service_title_in, seller_id_in, category_name_in, cost_in, description_in, current_date)
	RETURNING service_id INTO service_id_out;
	
	FOREACH tag_name IN ARRAY tags
	LOOP
		INSERT INTO tags(tag, service_id) VALUES (tag_name, service_id_out);
	END LOOP;
	RETURN service_id_out;
END;
$$;


-- Add Options For Service (seller)
CREATE TYPE option_type AS (
	option_detail character varying(80),
	option_cost numeric(5)
);

CREATE OR REPLACE FUNCTION add_options(
	IN service_id_in int,
	VARIADIC option_arr option_type[]
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE 
	opt option_type;
BEGIN 
	FOREACH opt IN ARRAY option_arr
	LOOP
		INSERT INTO extra_options(service_id, option_detail, option_cost) 
			VALUES (service_id_in, opt.option_detail, opt.option_cost);
	END LOOP;
	
	IF (SELECT create_date FROM services WHERE service_id = service_id_in) <> current_date THEN
		UPDATE services SET update_date = current_date WHERE service_id = service_id_in;
	END IF;
	RETURN;
END;
$$;


-- Delete Options Of Service (seller)
CREATE OR REPLACE FUNCTION delete_options(
	IN service_id_in int,
	VARIADIC option_id_arr int[]
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE 
	opt int;
BEGIN
	DELETE FROM extra_options WHERE option_id = ANY (option_id_arr) AND service_id = service_id_in;
	
	IF (SELECT create_date FROM services WHERE service_id = service_id_in) <> current_date THEN
		UPDATE services SET update_date = current_date WHERE service_id = service_id_in;
	END IF;
	RETURN;
END;
$$;


-- Delete a service (seller)
CREATE OR REPLACE FUNCTION delete_service(service_id_in int)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN 
	DELETE FROM tags
	WHERE service_id = service_id_in;
	
	DELETE FROM extra_options
	WHERE service_id = service_id_in;
	
	DELETE FROM services
	WHERE service_id = service_id_in;
	RETURN;
END;
$$;


-- Show Working Services (seller)
CREATE OR REPLACE FUNCTION show_working_services(seller_id_in integer)
RETURNS SETOF buy
LANGUAGE plpgsql
AS $$
BEGIN 
	RETURN QUERY
		SELECT b.*
		FROM buy AS b JOIN services AS s USING(service_id)
		WHERE b.status = 'on' AND s.seller_id = seller_id_in;
END;
$$;


-- Update Status (seller)
CREATE OR REPLACE FUNCTION update_status(buy_id_in integer, status_in char(3))
RETURNS SETOF buy
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
		UPDATE buy
		SET status = status_in
		WHERE  buy_id = buy_id_in
		RETURNING *;
END;
$$;


-- Add Skills (admin)
CREATE OR REPLACE FUNCTION add_skills(VARIADIC skill_name_in VARCHAR(30)[])
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO skills
		SELECT * FROM unnest(skill_name_in);
END;
$$;


-- Add Categories (admin)
CREATE OR REPLACE FUNCTION add_categories(VARIADIC category_name_in VARCHAR(30)[])
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO categories
	 	SELECT * FROM unnest(category_name_in);
END;
$$;


-- Count Seller (admin)
CREATE OR REPLACE FUNCTION count_seller()
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE 
 	count_seller INT;
BEGIN 
	count_seller = (SELECT COUNT(seller_id) FROM sellers);
	RETURN count_seller;
END;
$$;


-- Count Buyer (admin)
CREATE OR REPLACE FUNCTION count_buyer()
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE 
 	count_buyer INT;
BEGIN 
	count_buyer = (SELECT COUNT(buyer_id) FROM buyers);
	RETURN count_buyer;
END;
$$;


-- Count Order
CREATE OR REPLACE FUNCTION count_order(date_from DATE, date_to DATE)
RETURNS TABLE(
	count_orders INT,
	total_money NUMERIC(5,0)
)
LANGUAGE plpgsql
AS $$
DECLARE
	option_money NUMERIC(5,0);
BEGIN 
	SELECT COUNT(b.buy_id), SUM(s.cost) INTO count_orders, total_money
	FROM buy b JOIN services s USING(service_id)
	WHERE b.buy_date BETWEEN date_from AND date_to;
	
	option_money = (
		SELECT SUM(option_cost)
		FROM buy_option bo 
			JOIN extra_options eo USING(option_id, service_id)
	  		JOIN buy b USING(buy_id)
		WHERE b.buy_date BETWEEN date_from AND date_to);
	
	IF option_money IS NOT NULL THEN
		total_money = total_money + option_money;
	END IF;
	
	RETURN QUERY
		SELECT count_orders, total_money;
END;
$$;