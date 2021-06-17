COPY buyers (first_name, last_name, username, password, age, email) FROM 'D:/Project_Database/data_files/Buyers.csv' CSV HEADER ENCODING 'UTF8';

COPY sellers FROM 'D:/Project_Database/data_files/Sellers.csv' CSV HEADER ENCODING 'UTF8';

COPY skills FROM 'D:/Project_Database/data_files/Skills.csv' CSV HEADER ENCODING 'UTF8';

COPY seller_skill FROM 'D:/Project_Database/data_files/Seller_Skill.csv' CSV HEADER ENCODING 'UTF8';

COPY categories FROM 'D:/Project_Database/data_files/Categories.csv' CSV HEADER ENCODING 'UTF8';

COPY services (service_title, seller_id, category_name, cost, description, create_date, update_date) FROM 'D:/Project_Database/data_files/Services.csv' CSV HEADER ENCODING 'UTF8';

COPY tags FROM 'D:/Project_Database/data_files/Tags.csv' CSV HEADER ENCODING 'UTF8';

COPY extra_options (service_id, option_detail, option_cost) FROM 'D:/Project_Database/data_files/Extra_Options.csv' CSV HEADER ENCODING 'UTF8';

COPY buy (buyer_id, service_id, status, quantity, buy_date) FROM 'D:/Project_Database/data_files/Buy.csv' CSV HEADER ENCODING 'UTF8';

COPY buy_option FROM 'D:/Project_Database/data_files/Buy_Option.csv' CSV HEADER ENCODING 'UTF8';