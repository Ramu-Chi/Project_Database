CREATE INDEX idx_buyers_username ON Buyers (username);

CREATE INDEX idx_buy_buyerid_serviceid ON Buy (buyer_id, service_id);

CREATE INDEX idx_buyoption ON Buy_Option (option_id, service_id);

CREATE INDEX idx_extraoptions On Extra_Options (service_id);

CREATE INDEX idx_tags ON Tags (service_id);

CREATE INDEX idx_services_cat ON Services (category_name);