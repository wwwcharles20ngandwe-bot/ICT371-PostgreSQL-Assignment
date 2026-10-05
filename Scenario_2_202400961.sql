CREATE TABLE lab_sessions (
    session_id SERIAL PRIMARY KEY,
    session_name VARCHAR(100) NOT NULL,
    available_workstations INTEGER NOT NULL
);

CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    lecturer VARCHAR(100) NOT NULL,
    session_id INTEGER NOT NULL,
    workstations INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL
);

INSERT INTO lab_sessions (session_name, available_workstations)
VALUES
('Database Practical', 30),
('Networking Practical', 20),
('Programming Practical', 15);

DO $$
DECLARE
    available INTEGER;
BEGIN

    SELECT available_workstations
    INTO available
    FROM lab_sessions
    WHERE session_id = 1;

    IF available = 0 THEN
        RAISE NOTICE 'Session is full.';

    ELSIF available <= 5 THEN
        RAISE NOTICE 'Session is nearly full.';

    ELSE
        RAISE NOTICE 'Session has enough workstations.';
    END IF;

END $$;

DO $$
DECLARE
    counter INTEGER := 1;
BEGIN

    WHILE counter <= 3 LOOP
        RAISE NOTICE 'Session preparation reminder: %', counter;
        counter := counter + 1;
    END LOOP;

    FOR counter IN 1..3 LOOP
        RAISE NOTICE 'Workstation check: %', counter;
    END LOOP;

END $$;

CREATE OR REPLACE PROCEDURE reserve_workstations(
    p_lecturer VARCHAR,
    p_session_id INTEGER,
    p_workstations INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    available INTEGER;
BEGIN

    SELECT available_workstations
    INTO available
    FROM lab_sessions
    WHERE session_id = p_session_id;

    IF available IS NULL THEN
        RAISE EXCEPTION 'Session does not exist.';
    END IF;

    IF p_workstations <= 0 THEN
        RAISE EXCEPTION 'Number of workstations must be greater than zero.';
    END IF;

    IF available >= p_workstations THEN

        UPDATE lab_sessions
        SET available_workstations =
            available_workstations - p_workstations
        WHERE session_id = p_session_id;

        INSERT INTO reservations
        (lecturer, session_id, workstations, status)
        VALUES
        (p_lecturer, p_session_id, p_workstations, 'RESERVED');

        RAISE NOTICE 'Workstations reserved successfully.';

    ELSE
        RAISE NOTICE 'Not enough workstations available.';
    END IF;

END;
$$;

CALL reserve_workstations('Mr Banda', 1, 10);
CALL reserve_workstations('Mrs Phiri', 2, 5);
CALL reserve_workstations('Mr Zulu', 2, 30);

SELECT * FROM lab_sessions;
SELECT * FROM reservations;

CREATE OR REPLACE PROCEDURE cancel_reservation(
    p_reservation_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_session_id INTEGER;
    v_workstations INTEGER;
    v_status VARCHAR(20);
BEGIN

    SELECT session_id, workstations, status
    INTO v_session_id, v_workstations, v_status
    FROM reservations
    WHERE reservation_id = p_reservation_id;

    IF v_status IS NULL THEN
        RAISE NOTICE 'Reservation does not exist.';

    ELSIF v_status = 'RESERVED' THEN

        UPDATE lab_sessions
        SET available_workstations =
            available_workstations + v_workstations
        WHERE session_id = v_session_id;

        UPDATE reservations
        SET status = 'CANCELLED'
        WHERE reservation_id = p_reservation_id;

        RAISE NOTICE 'Reservation cancelled successfully.';

    ELSE
        RAISE NOTICE 'Reservation has already been cancelled.';
    END IF;

END;
$$;


CALL cancel_reservation(1);
CALL cancel_reservation(1);

DO $$
DECLARE
    session_record RECORD;

    session_cursor CURSOR FOR
        SELECT session_id, session_name, available_workstations
        FROM lab_sessions
        WHERE available_workstations <= 5;

BEGIN

    OPEN session_cursor;

    LOOP

        FETCH session_cursor INTO session_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
        'Session: %, Workstations remaining: %',
        session_record.session_name,
        session_record.available_workstations;

    END LOOP;

    CLOSE session_cursor;

END $$;

DO $$
BEGIN

    BEGIN

        CALL reserve_workstations('Mr Mwansa', 1, 0);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Invalid quantity: %', SQLERRM;

    END;

END $$;

SELECT * FROM lab_sessions;
SELECT * FROM reservations;