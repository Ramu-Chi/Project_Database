CREATE OR REPLACE FUNCTION option_id_auto()
    RETURNS trigger AS $$
BEGIN
    SELECT  COALESCE(MAX(option_id) + 1, 1)
    INTO    NEW.option_id
    FROM    extra_options
    WHERE   service_id = NEW.service_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql STRICT;

CREATE TRIGGER option_id_auto
    BEFORE INSERT ON extra_options
    FOR EACH ROW WHEN (NEW.option_id = 0)
    EXECUTE PROCEDURE option_id_auto();