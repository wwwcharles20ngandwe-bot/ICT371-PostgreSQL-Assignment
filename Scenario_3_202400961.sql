CREATE TABLE hostel_rooms (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(20) NOT NULL,
    available_bed_spaces INTEGER NOT NULL
);

CREATE TABLE allocations (
    allocation_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL,
    room_id INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL
);

INSERT INTO hostel_rooms (room_number, available_bed_spaces)
VALUES
('A101', 4),
('A102', 2),
('A103', 1);


DO $$
DECLARE
    spaces INTEGER;
BEGIN

    SELECT available_bed_spaces
    INTO spaces
    FROM hostel_rooms
    WHERE room_id = 1;

    IF spaces = 0 THEN
        RAISE NOTICE 'Room is full.';

    ELSIF spaces = 1 THEN
        RAISE NOTICE 'Room has one space left.';

    ELSE
        RAISE NOTICE 'Room has several spaces.';
    END IF;

END $$;

DO $$
DECLARE
    counter INTEGER := 1;
BEGIN

    WHILE counter <= 3 LOOP
        RAISE NOTICE 'Hostel inspection day: %', counter;
        counter := counter + 1;
    END LOOP;

    FOR counter IN 1..3 LOOP
        RAISE NOTICE 'Room check number: %', counter;
    END LOOP;

END $$;


CREATE OR REPLACE PROCEDURE allocate_room(
    p_student_number VARCHAR,
    p_room_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    spaces INTEGER;
BEGIN

    SELECT available_bed_spaces
    INTO spaces
    FROM hostel_rooms
    WHERE room_id = p_room_id;

    IF spaces IS NULL THEN
        RAISE EXCEPTION 'Room does not exist.';
    END IF;

    IF spaces > 0 THEN

        UPDATE hostel_rooms
        SET available_bed_spaces =
            available_bed_spaces - 1
        WHERE room_id = p_room_id;

        INSERT INTO allocations
        (student_number, room_id, status)
        VALUES
        (p_student_number, p_room_id, 'ALLOCATED');

        RAISE NOTICE 'Room allocated successfully.';

    ELSE
        RAISE NOTICE 'Room is full.';
    END IF;

END;
$$;

CALL allocate_room('202406598', 3);
CALL allocate_room('202406599', 3);
CALL allocate_room('202406600', 3);

SELECT * FROM hostel_rooms;
SELECT * FROM allocations;


CREATE OR REPLACE PROCEDURE check_out(
    p_allocation_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_room_id INTEGER;
    v_status VARCHAR(20);
BEGIN

    SELECT room_id, status
    INTO v_room_id, v_status
    FROM allocations
    WHERE allocation_id = p_allocation_id;

    IF v_status IS NULL THEN
        RAISE NOTICE 'Allocation does not exist.';

    ELSIF v_status = 'ALLOCATED' THEN

        UPDATE hostel_rooms
        SET available_bed_spaces =
            available_bed_spaces + 1
        WHERE room_id = v_room_id;

        UPDATE allocations
        SET status = 'COMPLETED'
        WHERE allocation_id = p_allocation_id;

        RAISE NOTICE 'Student checked out successfully.';

    ELSE
        RAISE NOTICE 'Student has already checked out.';
    END IF;

END;
$$;

CALL check_out(1);
CALL check_out(1);

DO $$
DECLARE
    room_record RECORD;

    room_cursor CURSOR FOR
        SELECT room_id, room_number, available_bed_spaces
        FROM hostel_rooms
        WHERE available_bed_spaces <= 1;

BEGIN

    OPEN room_cursor;

    LOOP

        FETCH room_cursor INTO room_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
        'Room: %, Available spaces: %',
        room_record.room_number,
        room_record.available_bed_spaces;

    END LOOP;

    CLOSE room_cursor;

END $$;


DO $$
BEGIN

    BEGIN

        CALL allocate_room('', 1);

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Invalid student number: %', SQLERRM;

    END;

END $$;

SELECT * FROM hostel_rooms;
SELECT * FROM allocations;