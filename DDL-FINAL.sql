CREATE DATABASE IF NOT EXISTS Cooking_Contest;
USE Cooking_Contest;



CREATE TABLE if not exists Recipes (
  Recipe_Number INT,
  Recipe_Name VARCHAR(50),
  Recipe_Type VARCHAR(50),
  Nationality VARCHAR(50),
  Recipe_Description VARCHAR(100),
  Meal VARCHAR(50),
Meal_Category VARCHAR(50),
  Difficulty_level INT,
  Tips VARCHAR(100),
  Theme_Name VARCHAR(50),
  PRIMARY KEY (Recipe_Number)
);


CREATE TABLE Cooks (
  Cook_ID INT,
  First_name VARCHAR(50),
  Last_name VARCHAR(50),
  Phone_Number varchar(20),
  Birth_Date VARCHAR(30),
  Age INT,
  Experience INT,
  Chef_Rank VARCHAR(40),
  Specialty VARCHAR(30),
  Role VARCHAR(200),
  PRIMARY KEY (Cook_ID)
);


CREATE TABLE Food_Group (
  Basic_ingredient VARCHAR(100),
  Group_name VARCHAR(100),
  Group_Desc VARCHAR(100),
  PRIMARY KEY (Basic_ingredient) 
);


CREATE TABLE Ingredients (
  Recipe_ingredients VARCHAR(200),
  Basic_ingredient VARCHAR(100),
  Recipe_kind CHAR(50),
  Recipe_Number  INT,
  PRIMARY KEY (Recipe_number),
FOREIGN KEY (Basic_ingredient) REFERENCES Food_Group(Basic_ingredient)
);

CREATE TABLE Theme (
  Theme_name VARCHAR(50),
  Theme_Desc VARCHAR(100),
recipe_number int,
  PRIMARY KEY (recipe_number)
);

CREATE TABLE Kitchenware (
  kitchenware_Type  VARCHAR(100),
  Use_direction  VARCHAR(100),
  PRIMARY KEY (kitchenware_Type )
);


CREATE TABLE Requires  (
  Recipe_Number  int,
  kitchenware_used VARCHAR(200),
FOREIGN KEY (recipe_number) REFERENCES recipes(recipe_number)
);




CREATE TABLE Execution (
  Steps VARCHAR(500),
  Step_Number INT,
  Cooking_time VARCHAR(10),
  Prep_time VARCHAR(10),
  Portions int,
  Recipe_Number int,
  PRIMARY KEY (Steps)
);


DELIMITER $$
CREATE FUNCTION CalculateCalories (
    fats INT,
    protein INT,
    carbs INT
) RETURNS INT
BEGIN
    DECLARE total_calories INT;
    

    SET total_calories = (fats * 9) + (protein * 4) + (carbs* 4);
    
    RETURN total_calories;
END$$
DELIMITER ;


CREATE TABLE Nutritional_Value (
  total_Calories int,
  Fats int,
  Protein int,
  Carbs int,
  Recipe_number int,
  PRIMARY KEY (recipe_number)
  
);

create table episodes
( episode_number int,
primary key (episode_number)  );

create table score(
total_score int,
episode_number int,
cook_id int,
Foreign key (episode_number) references episodes(episode_number),
Foreign key (cook_id) references cooks(cook_id) );



create table stars (
episode_number int,
 cook_id int)
 ;
 alter table stars add foreign key (episode_number) references episodes(episode_number);


CREATE TABLE Participations  (
  Episode_Number varchar(100),
  Recipe_Number  INT,
cook_id int,
FOREIGN KEY (cook_id) REFERENCES cooks(cook_id)
);

CREATE TEMPORARY TABLE temp_random_values AS
SELECT 
    (SELECT recipe_number FROM recipes ORDER BY RAND() LIMIT 1) AS random_value_1,
    (SELECT episode_number FROM episodes ORDER BY RAND() LIMIT 1) AS random_value_2
FROM
    information_schema.tables
LIMIT 600;

DELIMITER //

CREATE TRIGGER prevent_consecutive_stars
BEFORE INSERT ON stars
FOR EACH ROW
BEGIN
    DECLARE last_episode INT;
    DECLARE same_judge_count INT;
    
    -- Βρίσκουμε τον αριθμό του τελευταίου επεισοδίου που προστέθηκε η κριτική
    SELECT MAX(episode_number) INTO last_episode
    FROM stars
    WHERE cook_id = NEW.cook_id;
    
    -- Ελέγχουμε αν ο ίδιος κριτής έχει βαθμολογήσει σε τρία συνεχόμενα επεισόδια
    IF last_episode IS NOT NULL THEN
        SELECT COUNT(*) INTO same_judge_count
        FROM stars
        WHERE cook_id = NEW.cook_id
        AND episode_number >= last_episode - 2;
        
        IF same_judge_count >= 3 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ο ίδιος κριτής δεν μπορεί να βαθμολογήσει σε τρία συνεχόμενα επεισόδια.';
        END IF;
    END IF;
END//

delimiter;








DELIMITER //

CREATE TRIGGER check_mandatory_roles
BEFORE INSERT ON stars
FOR EACH ROW
BEGIN
    DECLARE representative_count INT;
    DECLARE judge_count INT;
    
    -- Ελέγχουμε τον αριθμό των μαγειρέματων ρόλων εκπροσώπων
    SELECT COUNT(*) INTO representative_count
    FROM cooks
    WHERE cooks.`Role` = 'representative';
    
    -- Ελέγχουμε τον αριθμό των μαγείρων ρόλων κριτών
    SELECT COUNT(*) INTO judge_count
    FROM cooks
    WHERE cooks.`Role` = 'judge';
    
    -- Εάν δεν υπάρχουν αρκετοί μάγειρες με τους συγκεκριμένους ρόλους, εκτοξεύουμε ένα σφάλμα
    IF representative_count < 10 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Δεν υπάρχουν αρκετοί μάγειρες με ρόλο εκπροσώπου στον πίνακα cooks.';
    END IF;
    
    IF judge_count < 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Δεν υπάρχουν αρκετοί μάγειρες με ρόλο κριτή στον πίνακα cooks.';
    END IF;
    

END//

DELIMITER ;

DELIMITER //
CREATE TRIGGER calculate_winner AFTER INSERT ON score
FOR EACH ROW
BEGIN
    DECLARE max_score INT;
    DECLARE winner_id INT;
    

    SET max_score = (
        SELECT MAX(total_score) 
        FROM score 
        WHERE episode_number = NEW.episode_number
    );
    

    SET winner_id = (
        SELECT cook_id 
        FROM score 
        WHERE episode_number = NEW.episode_number AND total_score = max_score 
        ORDER BY max_score DESC 
        LIMIT 1
    );
    

END;
//
DELIMITER ;

DELIMITER //

CREATE TRIGGER before_recipe_update
BEFORE UPDATE ON Recipes
FOR EACH ROW
BEGIN
  DECLARE user_count INT;
  SELECT COUNT(*) INTO user_count 
  FROM cooks
  WHERE Recipe_Number = NEW.Recipe_Number 
  AND User_ID = CURRENT_USER();

  IF user_count = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Δεν εχεις δικαιωμα να κανεις αυτη την ενημερωση';
  END IF;
END//

DELIMITER ;


CREATE USER 'cooks'@'%' IDENTIFIED BY '1234' ;


GRANT SELECT, UPDATE ON COOKING_CONTEST.Cooks TO 'cooks'@'%';

GRANT INSERT ON COOKING_CONTEST.Recipes TO 'cooks'@'%';


GRANT SELECT, UPDATE ON cooking_contest.Recipes TO 'cooks'@'%';
GRANT SELECT ON cooking_contest.participations TO 'cooks'@'%';


CREATE USER 'admin_user'@'%' IDENTIFIED BY 'mariligiwrgos';

GRANT ALL PRIVILEGES ON *.* TO 'admin_user'@'%' WITH GRANT OPTION;

GRANT LOCK TABLES, RELOAD, SHOW DATABASES, REPLICATION CLIENT, FILE ON *.* TO 'admin_user'@'%';

FLUSH PRIVILEGES;


