CREATE TABLE IF NOT EXISTS Buyers (
	buyer_id SERIAL PRIMARY KEY,
	first_name VARCHAR(20),
	last_name VARCHAR(20),
	username VARCHAR(30) UNIQUE NOT NULL,
	password VARCHAR(30) NOT NULL,
	age INTEGER CHECK (age > 0),
	email VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS Sellers (
	seller_id INTEGER PRIMARY KEY REFERENCES Buyers(buyer_id)
);

CREATE TABLE IF NOT EXISTS Skills (
	skill_name VARCHAR(40) PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS Seller_Skill (
	seller_id INTEGER REFERENCES Sellers(seller_id),
	skill_name VARCHAR(40) REFERENCES Skills(skill_name),
	PRIMARY KEY (seller_id, skill_name)
);

CREATE TABLE IF NOT EXISTS Categories (
	category_name VARCHAR(30) PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS Services (
	service_id SERIAL PRIMARY KEY,
	service_title VARCHAR(90),
	seller_id INTEGER REFERENCES Sellers(seller_id),
	category_name VARCHAR(30) REFERENCES Categories(category_name),
	cost NUMERIC(5, 0) CHECK (cost > 0),
	description VARCHAR(1200),
	create_date DATE,
	update_date Date CHECK (update_date >= create_date),
	UNIQUE (service_title, seller_id)
);

CREATE TABLE IF NOT EXISTS Tags (
	tag VARCHAR(30),
	service_id INTEGER REFERENCES Services(service_id),
	PRIMARY KEY (tag, service_id)
);

CREATE TABLE IF NOT EXISTS Extra_Options (
	option_id INTEGER DEFAULT 0,
	service_id INTEGER REFERENCES Services(service_id),
	option_detail VARCHAR(80),
	option_cost NUMERIC(5, 0) CHECK (option_cost > 0),
	PRIMARY KEY (option_id, service_id)
);

CREATE TABLE IF NOT EXISTS Buy (
	buy_id SERIAL PRIMARY KEY,
	buyer_id INTEGER REFERENCES Buyers(buyer_id),
	service_id INTEGER REFERENCES Services(service_id),
	status CHAR(3) CHECK (status IN ('on', 'off')),
	quantity INTEGER CHECK (quantity > 0),
	buy_date DATE
);

CREATE TABLE IF NOT EXISTS Buy_Option (
	buy_id INTEGER REFERENCES Buy(buy_id),
	option_id INTEGER,
	service_id INTEGER,
	PRIMARY KEY (buy_id, option_id),
	FOREIGN KEY (option_id, service_id) REFERENCES Extra_Options(option_id, service_id)
)