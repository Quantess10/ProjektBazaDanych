/*
ALTER TABLE WYPOZYCZENIA DROP CONSTRAINT WYPOZYCZENIA_AUTA_FK;
ALTER TABLE WYPOZYCZENIA DROP CONSTRAINT WYPOZYCZENIA_KLIENCI_FK;
ALTER TABLE WYPOZYCZENIA DROP CONSTRAINT WYPOZYCZENIA_PRACOWNICY_FK;
ALTER TABLE WYPOZYCZENIA DROP CONSTRAINT WYPOZYCZENIA_OPLATY_FK;

DROP TABLE AUTA;
DROP TABLE KLIENCI;
DROP TABLE PRACOWNICY;
DROP TABLE WYPOZYCZENIA;
DROP TABLE OPLATY;
*/


--Dodawanie tabel

-- Tabela AUTA przechowuje informacje o pojazdach dostępnych w wypożyczalni
-- ID: Unikalny identyfikator pojazdu
-- MARKA, MODEL, TYP: Informacje o pojeździe
-- ROK_PRODUKCJI: Rok produkcji pojazdu jako czterocyfrowa liczba, musi być większy niż 1900 i mniejsza niż obecny rok (sprawdzane triggerem)
-- DOSTEPNOSC: Status dostępności pojazdu, 'T' dla dostępnego, 'N' dla niedostępnego
CREATE TABLE AUTA (
    ID NUMBER NOT NULL,
    MARKA VARCHAR2(100) NOT NULL,
    MODEL VARCHAR2(100) NOT NULL,
    TYP VARCHAR(50),
    ROK_PRODUKCJI NUMBER(4),
    DOSTEPNOSC CHAR(1) DEFAULT 'T',
    CONSTRAINT AUTA_PK PRIMARY KEY (ID),
    CONSTRAINT DOSTEPNOSC_CHK CHECK (DOSTEPNOSC IN ('T', 'N'))
);

-- Tabela KLIENCI przechowuje informacje o klientach wypożyczalni
-- ID: Unikalny identyfikator klienta
-- IMIE, NAZWISKO, NUMER_PRAWA JAZDY: Dane klienta
-- EMAIL, NUMER_TELEFONU: Dane kontaktowe klienta
CREATE TABLE KLIENCI (
    ID NUMBER NOT NULL,
    IMIE VARCHAR2(100) NOT NULL,
    NAZWISKO VARCHAR(100) NOT NULL,
    EMAIL VARCHAR(100),
    NUMER_TELEFONU VARCHAR(15) NOT NULL,
    NUMER_PRAWA_JAZDY VARCHAR(20) NOT NULL,
    CONSTRAINT KLIENCI_PK PRIMARY KEY (ID),
    CONSTRAINT NUMER_PRAWA_JAZDY_UNIQUE UNIQUE (NUMER_PRAWA_JAZDY)
);

-- Tabela PRACOWNICY przechowuje informacje o pracownikach wypożyczalni
-- ID: Unikalny identyfikator pracownika
-- IMIE, NAZWISKO: Dane pracownika
-- EMAIL, NUMER_TELEFONU: Dane kontaktowe pracownika
-- ILOSC_WYPOZYCZONYCH_AUT: Informacja ile aut zostało wypożyczonych przez pracownika
CREATE TABLE PRACOWNICY (
    ID NUMBER NOT NULL,
    IMIE VARCHAR2(100) NOT NULL,
    NAZWISKO VARCHAR(100) NOT NULL,
    STANOWISKO VARCHAR(50) NOT NULL,
    EMAIL VARCHAR(100),
    NUMER_TELEFONU VARCHAR(15) NOT NULL,
    ILOSC_WYPOZYCZONYCH_AUT NUMBER DEFAULT 0,
    CONSTRAINT PRACOWNICY_PK PRIMARY KEY (ID)
);

-- Tabela OPLATY przechowuje informacje na temat opłat za wypożyczenie auta na dany okres czasu
-- ID: Unikalny identyfikator opłaty za wypożyczenie
-- CENA_ZA_DZIEN: Kwota do zapłaty za każdy dzień wypożyczenia auta
-- ILOSC_DNI: Ilość dni na ile wypożyczono auto
-- DO_ZAPLATY: Łączna kwota należna do zapłaty za wypożyczenie auta
-- KARA_ZA_DZIEN_ZWLOKI: Kara do zapłaty za każdy dzień zwłoki z oddaniem auta
CREATE TABLE OPLATY (
    ID NUMBER NOT NULL,
    CENA_ZA_DZIEN NUMBER,
    ILOSC_DNI NUMBER,
    DO_ZAPLATY NUMBER,
    KARA_ZA_DZIEN_ZWLOKI NUMBER,
    CONSTRAINT OPLATY_PK PRIMARY KEY (ID),
    CONSTRAINT CENA_ZA_DZIEN_CHK CHECK (CENA_ZA_DZIEN >= 0),
    CONSTRAINT ILOSC_DNI_CHK CHECK (ILOSC_DNI >= 1),
    CONSTRAINT DO_ZAPLATY_CHK CHECK (DO_ZAPLATY >= 0),
    CONSTRAINT KARA_ZA_DZIEN_ZWLOKI_CHK CHECK (KARA_ZA_DZIEN_ZWLOKI >= 0)
);

-- Tabela WYPOZYCZENIA przechowuje informacje na temat wypożyczeń aut
-- ID: Unikalny identyfikator wypożyczenia
-- AUTO_ID: ID auta z tabeli AUTA
-- KLIENT_ID: ID klienta z tabeli KLIENCI
-- PRACOWNIK_ID: ID pracownika z tabeli PRACOWNICY
-- OPLATA_ID: ID opłaty z tabeli OPLATY
-- DATA_WYPOŻYCZENIA: Data wypożyczenia auta, domyślnie dzisiejsza data systemowa
-- DATA_ZWROTU: Data zwrotu auta
CREATE TABLE WYPOZYCZENIA (
    ID NUMBER NOT NULL,
    AUTO_ID NUMBER NOT NULL,
    KLIENT_ID NUMBER NOT NULL,
    PRACOWNIK_ID NUMBER NOT NULL,
    OPLATA_ID NUMBER NOT NULL,
    DATA_WYPOZYCZENIA DATE DEFAULT SYSDATE NOT NULL,
    DATA_ZWROTU DATE,
    CONSTRAINT WYPOZYCZENIA_PK PRIMARY KEY (ID),
    CONSTRAINT WYPOZYCZENIA_AUTA_FK FOREIGN KEY (AUTO_ID) REFERENCES AUTA(ID),
    CONSTRAINT WYPOZYCZENIA_KLIENCI_FK FOREIGN KEY (KLIENT_ID) REFERENCES KLIENCI(ID),
    CONSTRAINT WYPOZYCZENIA_PRACOWNICY_FK FOREIGN KEY (PRACOWNIK_ID) REFERENCES PRACOWNICY(ID),
    CONSTRAINT WYPOZYCZENIA_OPLATY_FK FOREIGN KEY (OPLATA_ID) REFERENCES OPLATY(ID),
    CONSTRAINT DATA_ZWROTU_CHK CHECK (DATA_ZWROTU >= DATA_WYPOZYCZENIA)
);

-- Dodawanie indeksów
CREATE INDEX IDX_MARKA ON AUTA(MARKA);
CREATE INDEX IDX_NAZWISKO_KLIENT ON KLIENCI(NAZWISKO);
CREATE INDEX IDX_EMAIL_KLIENT ON KLIENCI(EMAIL);
CREATE INDEX IDX_NAZWISKO_PRACOWNIK ON PRACOWNICY(NAZWISKO);
CREATE INDEX IDX_EMAIL_PRACOWNIK ON PRACOWNICY(EMAIL);
CREATE INDEX IDX_AUTO_ID ON WYPOZYCZENIA(AUTO_ID);
CREATE INDEX IDX_KLIENT_ID ON WYPOZYCZENIA(KLIENT_ID);
CREATE INDEX IDX_PRACOWNIK_ID ON WYPOZYCZENIA(PRACOWNIK_ID);
CREATE INDEX IDX_DATA_WYPOZYCZENIA ON WYPOZYCZENIA(DATA_WYPOZYCZENIA);
CREATE INDEX IDX_DATA_ZWROTU ON WYPOZYCZENIA(DATA_ZWROTU);

-- Dodawanie wyzwalaczy

-- Ustawienie dostępności auta na T po aktualizacji daty zwrotu auta
CREATE OR REPLACE TRIGGER DOSTEPNOSC_TRG
AFTER UPDATE OF DATA_ZWROTU OR INSERT ON WYPOZYCZENIA
FOR EACH ROW
BEGIN
    UPDATE AUTA
    SET DOSTEPNOSC = 'T'
    WHERE ID = :NEW.AUTO_ID;
END;

-- Weryfikacja czy wprowadzono poprawny rok produkcji auta - od 1900 do daty obecnej
CREATE OR REPLACE TRIGGER ROK_PRODUKCJI_TRG
BEFORE INSERT OR UPDATE ON AUTA
FOR EACH ROW
BEGIN
    IF :NEW.ROK_PRODUKCJI < 1900 OR :NEW.ROK_PRODUKCJI > EXTRACT(YEAR FROM SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20003, 'Rok produkcji musi być większy niż 1900 i nie może przekraczać bieżącego roku.');
    END IF;
END;

-- Zwiększenie wartości ilości wypożyczeń aut danemu pracownikowi po dodaniu rekordu do tabeli WYPOZYCZENIA
CREATE OR REPLACE TRIGGER ILOSC_WYPOZYCZONYCH_AUT_TRG
AFTER INSERT ON WYPOZYCZENIA
FOR EACH ROW
BEGIN
    UPDATE PRACOWNICY
    SET ILOSC_WYPOZYCZONYCH_AUT = ILOSC_WYPOZYCZONYCH_AUT + 1
    WHERE ID = :NEW.PRACOWNIK_ID;
END;

-- Liczenie łącznej kwoty do zapłaty za wypożyczenie auta
CREATE OR REPLACE TRIGGER DO_ZAPLATY_TRG
BEFORE INSERT OR UPDATE ON OPLATY
FOR EACH ROW
BEGIN
    :NEW.DO_ZAPLATY := :NEW.CENA_ZA_DZIEN * :NEW.ILOSC_DNI;
END;

-- Sprawdzenie, czy przekroczono ilość dni wypożyczenia auta. Jeśli tak - dolicza karę
CREATE OR REPLACE TRIGGER Calculate_Late_Fee
AFTER UPDATE OF DATA_ZWROTU ON WYPOZYCZENIA
FOR EACH ROW
DECLARE
  v_rental_days NUMBER;
  v_late_days NUMBER;
  v_daily_rate NUMBER;
  v_late_fee NUMBER;
  v_total_due NUMBER;
BEGIN
  -- Pobieranie liczby dni wypożyczenia i stawki dziennego wynajmu
  SELECT ILOSC_DNI, CENA_ZA_DZIEN INTO v_rental_days, v_daily_rate FROM OPLATY WHERE ID = :NEW.OPLATA_ID;

  -- Obliczanie liczby dni zwłoki
  v_late_days := :NEW.DATA_ZWROTU - (:NEW.DATA_WYPOZYCZENIA + v_rental_days);

  IF v_late_days > 0 THEN
    -- Obliczanie kary za zwłokę
    SELECT KARA_ZA_DZIEN_ZWLOKI INTO v_late_fee FROM OPLATY WHERE ID = :NEW.OPLATA_ID;
    v_total_due := v_late_days * v_late_fee;

    -- Aktualizacja łącznej kwoty do zapłaty
    UPDATE OPLATY
    SET DO_ZAPLATY = DO_ZAPLATY + v_total_due
    WHERE ID = :NEW.OPLATA_ID;
  END IF;
END;

-- Weryfikacja poprawności wporadzonego maila dla klienta
CREATE OR REPLACE TRIGGER EMAIL_KLIENT_TRG
BEFORE INSERT OR UPDATE OF EMAIL ON KLIENCI
FOR EACH ROW
BEGIN
    IF NOT REGEXP_LIKE(:NEW.EMAIL, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
    RAISE_APPLICATION_ERROR(-20001, 'Nieprawidłowy format emaila.');
  END IF;
END;

-- Weryfikacja poprawności wporadzonego maila dla pracownika
CREATE OR REPLACE TRIGGER EMAIL_PRACOWNIK_TRG
BEFORE INSERT OR UPDATE OF EMAIL ON PRACOWNICY
FOR EACH ROW
BEGIN
    IF NOT REGEXP_LIKE(:NEW.EMAIL, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
    RAISE_APPLICATION_ERROR(-20001, 'Nieprawidłowy format emaila.');
  END IF;
END;

-- Weryfikacja poprawności wprowadzonego numeru telefonu dla klienta
CREATE OR REPLACE TRIGGER NUMER_TELEFONU_KLIENT_TRG
BEFORE INSERT OR UPDATE OF NUMER_TELEFONU ON KLIENCI
FOR EACH ROW
BEGIN
  IF NOT REGEXP_LIKE(:NEW.NUMER_TELEFONU, '^\+48\s?[1-9][0-9]{8}$|^[1-9][0-9]{8}$') THEN
    RAISE_APPLICATION_ERROR(-20002, 'Nieprawidłowy format numeru telefonu. Akceptowany format to +48 123456789 lub 123456789.');
  END IF;
END;

-- Weryfikacja poprawności wprowadzonego numeru telefonu dla PRACOWNIKA
CREATE OR REPLACE TRIGGER NUMER_TELEFONU_PRACOWNIK_TRG
BEFORE INSERT OR UPDATE OF NUMER_TELEFONU ON PRACOWNICY
FOR EACH ROW
BEGIN
  IF NOT REGEXP_LIKE(:NEW.NUMER_TELEFONU, '^\+48\s?[1-9][0-9]{8}$|^[1-9][0-9]{8}$') THEN
    RAISE_APPLICATION_ERROR(-20002, 'Nieprawidłowy format numeru telefonu. Akceptowany format to +48 123456789 lub 123456789.');
  END IF;
END;


/*
SELECT * FROM AUTA;
SELECT * FROM KLIENCI;
SELECT * FROM PRACOWNICY;
SELECT * FROM WYPOZYCZENIA;
SELECT * FROM OPLATY;
*/