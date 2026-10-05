CREATE TABLE medicines (
    medicine_id SERIAL PRIMARY KEY,
    medicine_name VARCHAR(100) NOT NULL,
    stock_quantity INTEGER NOT NULL
);

CREATE TABLE dispensing_records (
    dispensing_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL,
    medicine_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL
);

INSERT INTO medicines (medicine_name, stock_quantity)
VALUES
('Paracetamol', 100),
('Amoxicillin', 50),
('Ibuprofen', 75);


DO $$
DECLARE
    stock INTEGER;
BEGIN

    SELECT stock_quantity
    INTO stock
    FROM medicines
    WHERE medicine_id = 1;

    IF stock = 0 THEN
        RAISE NOTICE 'Medicine is out of stock.';

    ELSIF stock <= 20 THEN
        RAISE NOTICE 'Medicine is low on stock.';

    ELSE
        RAISE NOTICE 'Medicine is sufficiently stocked.';
    END IF;

END $$;

DO $$
DECLARE
    counter INTEGER := 1;
BEGIN

    WHILE counter <= 3 LOOP
        RAISE NOTICE 'Stock review day: %', counter;
        counter := counter + 1;
    END LOOP;

    FOR counter IN 1..3 LOOP
        RAISE NOTICE 'Shelf inspection number: %', counter;
    END LOOP;

END $$;


CREATE OR REPLACE PROCEDURE dispense_medicine(
    p_student_number VARCHAR,
    p_medicine_id INTEGER,
    p_quantity INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_stock INTEGER;
BEGIN

    SELECT stock_quantity
    INTO current_stock
    FROM medicines
    WHERE medicine_id = p_medicine_id;

    IF current_stock IS NULL THEN
        RAISE EXCEPTION 'Medicine does not exist.';
    END IF;

    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be greater than zero.';
    END IF;

    IF current_stock >= p_quantity THEN

        UPDATE medicines
        SET stock_quantity =
            stock_quantity - p_quantity
        WHERE medicine_id = p_medicine_id;

        INSERT INTO dispensing_records
        (student_number, medicine_id, quantity, status)
        VALUES
        (p_student_number, p_medicine_id, p_quantity, 'DISPENSED');

        RAISE NOTICE 'Medicine dispensed successfully.';

    ELSE
        RAISE NOTICE 'Not enough medicine in stock.';
    END IF;

END;
$$;

CALL dispense_medicine('202406598', 1, 10);
CALL dispense_medicine('202406599', 2, 5);
CALL dispense_medicine('202406600', 2, 100);

SELECT * FROM medicines;
SELECT * FROM dispensing_records;


CREATE OR REPLACE PROCEDURE reverse_dispensing(
    p_dispensing_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_medicine_id INTEGER;
    v_quantity INTEGER;
    v_status VARCHAR(20);
BEGIN

    SELECT medicine_id, quantity, status
    INTO v_medicine_id, v_quantity, v_status
    FROM dispensing_records
    WHERE dispensing_id = p_dispensing_id;

    IF v_status IS NULL THEN
        RAISE NOTICE 'Dispensing record does not exist.';

    ELSIF v_status = 'DISPENSED' THEN

        UPDATE medicines
        SET stock_quantity =
            stock_quantity + v_quantity
        WHERE medicine_id = v_medicine_id;

        UPDATE dispensing_records
        SET status = 'REVERSED'
        WHERE dispensing_id = p_dispensing_id;

        RAISE NOTICE 'Dispensing reversed successfully.';

    ELSE
        RAISE NOTICE 'Dispensing record has already been reversed.';
    END IF;

END;
$$;

CALL reverse_dispensing(1);
CALL reverse_dispensing(1);


DO $$
DECLARE
    medicine_record RECORD;

    medicine_cursor CURSOR FOR
        SELECT medicine_id, medicine_name, stock_quantity
        FROM medicines
        WHERE stock_quantity < 20;

BEGIN

    OPEN medicine_cursor;

    LOOP

        FETCH medicine_cursor INTO medicine_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
        'Medicine: %, Stock: %',
        medicine_record.medicine_name,
        medicine_record.stock_quantity;

    END LOOP;

    CLOSE medicine_cursor;

END $$;

DO $$
BEGIN
    BEGIN
        CALL dispense_medicine('202406601', 1, -5);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Invalid quantity: %', SQLERRM;
    END;
END $$;

SELECT * FROM medicines;
SELECT * FROM dispensing_records;