-- --------------------------------------------------------
-- Хост:                         127.0.0.1
-- Версия сервера:               5.5.23 - MySQL Community Server (GPL)
-- Операционная система:         Win64
-- HeidiSQL Версия:              9.4.0.5194
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

-- Дамп структуры для таблица sklad.backfaktura
CREATE TABLE IF NOT EXISTS `backfaktura` (
  `backFakturaId` int(11) NOT NULL AUTO_INCREMENT,
  `fakturaDate` datetime NOT NULL,
  `providerId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`backFakturaId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.backfaktura: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `backfaktura` DISABLE KEYS */;
/*!40000 ALTER TABLE `backfaktura` ENABLE KEYS */;

-- Дамп структуры для таблица sklad.backrealize
CREATE TABLE IF NOT EXISTS `backrealize` (
  `backRealizeId` int(11) NOT NULL AUTO_INCREMENT,
  `backFakturaId` int(11) DEFAULT NULL,
  `prodId` int(11) DEFAULT NULL,
  `count` float DEFAULT NULL,
  `price` int(11) DEFAULT NULL,
  PRIMARY KEY (`backRealizeId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.backrealize: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `backrealize` DISABLE KEYS */;
/*!40000 ALTER TABLE `backrealize` ENABLE KEYS */;

-- Дамп структуры для представление sklad.backrealizeview
-- Создание временной таблицы для обработки ошибок зависимостей представлений
CREATE TABLE `backrealizeview` (
	`backRealizeId` INT(11) NOT NULL,
	`backFakturaId` INT(11) NOT NULL,
	`name` VARCHAR(150) NULL COLLATE 'utf8_general_ci',
	`fakturaDate` DATE NULL,
	`price` DOUBLE(17,0) NULL,
	`count` VARCHAR(41) NULL COLLATE 'utf8mb4_general_ci',
	`productId` INT(11) NOT NULL
) ENGINE=MyISAM;

-- Дамп структуры для процедура sklad.BackTrigger
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `BackTrigger`(IN `id` INT)
    COMMENT 'Процедура при возврате счета'
BEGIN

	DECLARE done INT DEFAULT 0;
	DECLARE bCount float;
	DECLARE orderCount float;
	DECLARE prodsID int;
	DECLARE expeSum float;
	DECLARE termSum float ;
	DECLARE cur1 CURSOR FOR SELECT o.prodId,o.packCount FROM orders o where o.expenseId = id;
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
	
	OPEN cur1;
	
	REPEAT
		FETCH cur1 INTO prodsID, orderCount;
		IF NOT done THEN
			SET bCount = prodBalance(prodsID);
			UPDATE balance	SET endCount = (bCount + orderCount) where prodId = prodsID;
		END IF;
	UNTIL done END REPEAT;
	
	CLOSE cur1;

	
	SET expeSum = (SELECT ex.expSum FROM expense ex where ex.expenseId = id);
	SET termSum = (SELECT ex.terminal FROM expense ex where ex.expenseId = id);
	
	UPDATE info SET proceed = (proceed - expeSum), nal = (nal - (expeSum - termSum)), terminal = (terminal - termSum), back = (back + expeSum) where Dates = date(now());
END//
DELIMITER ;

-- Дамп структуры для представление sklad.backview
-- Создание временной таблицы для обработки ошибок зависимостей представлений
CREATE TABLE `backview` (
	`expenseDate` DATETIME NULL,
	`count` FLOAT NULL,
	`name` VARCHAR(150) NULL COLLATE 'utf8_general_ci',
	`pack` INT(11) NOT NULL
) ENGINE=MyISAM;

-- Дамп структуры для таблица sklad.balance
CREATE TABLE IF NOT EXISTS `balance` (
  `balanceId` int(11) NOT NULL AUTO_INCREMENT,
  `prodId` int(11) DEFAULT NULL,
  `endCount` float DEFAULT NULL,
  `curEndCount` float DEFAULT NULL,
  `balanceDate` date DEFAULT NULL,
  PRIMARY KEY (`balanceId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.balance: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `balance` DISABLE KEYS */;
/*!40000 ALTER TABLE `balance` ENABLE KEYS */;

-- Дамп структуры для процедура sklad.balanceCalc
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `balanceCalc`()
    COMMENT 'Высчитывание остатка для текущего дня'
BEGIN
/*	DECLARE i INT;
	DECLARE prodID INT;
	DECLARE eCount float;
	DECLARE cEndCount float;
	DECLARE realizes float;
	DECLARE LastDate date;
	DECLARE expenses float;
	DECLARE back float;
	DECLARE temp float;
	DECLARE cDate date DEFAULT(date(now()));
	#SET cDate = '2017-05-12';
	SET i = (select productId from product order by productId DESC limit 1);
		delete from balanceList where balanceDate = cDate;
		delete from balance where balanceDate = '2000-01-01';
	SET LastDate = (select balanceDate from balanceList order by balanceDate DESC limit 1);
	
	WHILE i > 0 DO
	#SET i = 2784;
	
		SET prodID = (select productId from product where productId = i);
		IF(prodID is not NULL) THEN
			
			# Начальный остаток продукта
			#SET cEndCount = (select b.curEndCount from balance b where b.prodId = prodID and b.balanceDate = LastDate order by balanceDate DESC limit 1);
			#IF(cEndCount is NULL) THEN		
				SET eCount = (select b.endCount from balanceList b where b.prodId = i and b.balanceDate = LastDate limit 1);
			#ELSE		
			#	SET eCount = cEndCount;
			#END IF;
			
			
			#Приход продукта
			SET realizes = (select sum(r.count) from faktura f join realize r on r.fakturaId = f.fakturaId where r.prodId = prodID and date(f.fakturaDate) = cDate limit 1);
			IF (realizes is null) THEN 
				SET realizes = 0;
			END IF;
			
			#Расход товара 
			SET expenses = (select sum(o.packCount) from expense e join orders o on o.expenseId = e.expenseId where o.prodId = prodID and date(e.expenseDate) = cDate and e.expType != 1 limit 1);
			IF (expenses is null) THEN 
				SET expenses = 0;
			END IF;
			
			#Возврат товара 
			SET back = (select sum(o.packCount) from expense e join orders o on o.expenseId = e.expenseId where o.prodId = prodID and date(e.expenseDate) = cDate and e.expType = 1 limit 1);
			IF (back is null) THEN 
				SET back = 0;
			END IF;
			
			IF(eCount is null) THEN
				SET eCount = 0;
			END IF;
			
			SET temp = (eCount+realizes-expenses+back);
			#IF (cDate = LastDate) THEN
			#IF ((select b.balanceDate from balance b where b.prodId = i and b.balanceDate = LastDate limit 1) is not null) THEN
				# Insert в таблицу баланс
	#			insert into balance (`balanceDate`,`prodId`,`endCount`) values(date(now()),prodID,(eCount+realizes-expenses+back));
				#update balance  SET `endCount` = (eCount+realizes-expenses+back) where prodId = prodID and balanceDate = LastDate;
			#ELSE
				# Insert в таблицу баланс
				insert into balanceList (`balanceDate`,`prodId`,`endCount`) values(cDate,prodID,temp);
				insert into balance (`balanceDate`,`prodId`,`endCount`) values('2000-01-01',prodID,temp);
			#END IF;
			
		END IF;
		 SET i=i-1;
   END WHILE;*/

	DECLARE done INT DEFAULT 0;
	DECLARE bCount float;
	DECLARE bId float;
	DECLARE prodsID int;
	DECLARE cur1 CURSOR FOR SELECT b.prodId, b.balanceId FROM balance b;
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
	
	OPEN cur1;
	
	REPEAT
		FETCH cur1 INTO prodsID, bId;
		SET bId = (select b.balanceId from balance b where b.prodId = prodsID LIMIT 1);

			delete from balance where balanceId > bId and prodId = prodsID;

	UNTIL done END REPEAT;
END//
DELIMITER ;

-- Дамп структуры для таблица sklad.balancelist
CREATE TABLE IF NOT EXISTS `balancelist` (
  `balanceId` int(11) NOT NULL AUTO_INCREMENT,
  `balanceDate` date DEFAULT NULL,
  `prodId` int(11) DEFAULT NULL,
  `endCount` float DEFAULT NULL,
  `curEndCount` float DEFAULT NULL,
  PRIMARY KEY (`balanceId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.balancelist: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `balancelist` DISABLE KEYS */;
/*!40000 ALTER TABLE `balancelist` ENABLE KEYS */;

-- Дамп структуры для представление sklad.balanceview
-- Создание временной таблицы для обработки ошибок зависимостей представлений
CREATE TABLE `balanceview` (
	`balanceId` INT(11) NOT NULL,
	`balanceDate` DATE NULL,
	`prodId` INT(11) NULL,
	`curEndCount` DOUBLE(17,0) NULL,
	`price` INT(11) NULL,
	`endCount` DOUBLE NULL,
	`productId` INT(11) NOT NULL,
	`name` VARCHAR(150) NULL COLLATE 'utf8_general_ci',
	`measureId` INT(11) NULL,
	`barcode` VARCHAR(50) NULL COLLATE 'utf8_general_ci',
	`status` INT(11) NOT NULL,
	`pack` INT(11) NOT NULL
) ENGINE=MyISAM;

-- Дамп структуры для процедура sklad.calc
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `calc`(IN `id` INT, IN `t` VARCHAR(50), IN `cnt` FLOAT)
BEGIN

	DECLARE bCount FLOAT;

	IF (t = "plus") THEN
	
			SET bCount = prodBalance(id);
			UPDATE balance	SET endCount = (bCount + cnt) where balanceDate = '2000-01-01' and prodId = id;
	
	END IF;
	
	IF (t = "minus") THEN
	
			SET bCount = prodBalance(id);
			UPDATE balance	SET endCount = (bCount - cnt) where balanceDate = '2000-01-01' and prodId = id;
	
	END IF;

END//
DELIMITER ;

-- Дамп структуры для таблица sklad.changeprice
CREATE TABLE IF NOT EXISTS `changeprice` (
  `IDChangePrice` int(11) NOT NULL AUTO_INCREMENT,
  `IDFaktura` int(11) DEFAULT NULL,
  `DateChange` date DEFAULT NULL,
  `Price` int(11) DEFAULT NULL,
  `IDProduct` int(11) DEFAULT NULL,
  PRIMARY KEY (`IDChangePrice`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.changeprice: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `changeprice` DISABLE KEYS */;
/*!40000 ALTER TABLE `changeprice` ENABLE KEYS */;

-- Дамп структуры для таблица sklad.changesel
CREATE TABLE IF NOT EXISTS `changesel` (
  `changSelId` int(11) NOT NULL AUTO_INCREMENT,
  `userId` int(11) DEFAULT NULL,
  `startTime` datetime DEFAULT NULL,
  `endTime` datetime DEFAULT NULL,
  `summ` int(11) DEFAULT NULL,
  `terminal` int(11) DEFAULT NULL,
  `debt` int(11) DEFAULT NULL,
  `back` int(11) DEFAULT NULL,
  `expenseId` int(11) DEFAULT '0',
  PRIMARY KEY (`changSelId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.changesel: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `changesel` DISABLE KEYS */;
/*!40000 ALTER TABLE `changesel` ENABLE KEYS */;

-- Дамп структуры для функция sklad.checkRealize
DELIMITER //
CREATE DEFINER=`root`@`localhost` FUNCTION `checkRealize`(`id` INT, `bCount` FLOAT) RETURNS int(11)
    DETERMINISTIC
    COMMENT 'Проверка цены продукта по фактурам'
BEGIN

	DECLARE rCount INT DEFAULT(0);
	DECLARE i Int;
	DECLARE price Int;
	DECLARE facId Int DEFAULT(0);
	
	SET i = (select count(*) from faktura f join realize r on r.fakturaId = f.fakturaId where r.prodId = id);
	
	myloop: WHILE i > 0 DO
		IF(facId = 0) THEN 
			SET rCount = rCount + (select r.count from faktura f join realize r on r.fakturaId = f.fakturaId where r.prodId = id order by f.fakturaDate DESC limit 1);
			SET facId = (select f.fakturaId from faktura f join realize r on r.fakturaId = f.fakturaId where r.prodId = id order by f.fakturaDate DESC limit 1);
			SET price = (select r.soldPrice from faktura f join realize r on r.fakturaId = f.fakturaId where r.prodId = id order by f.fakturaDate DESC limit 1);
		ELSE
			SET rCount = rCount + (select r.count from faktura f join realize r on r.fakturaId = f.fakturaId where r.prodId = id AND f.fakturaId < facId order by f.fakturaDate DESC limit 1);
			SET price = (select r.soldPrice from faktura f join realize r on r.fakturaId = f.fakturaId where r.prodId = id AND f.fakturaId < facId order by f.fakturaDate DESC limit 1);
			SET facId = (select f.fakturaId from faktura f join realize r on r.fakturaId = f.fakturaId where r.prodId = id AND f.fakturaId < facId order by f.fakturaDate DESC limit 1);
		END IF;
		
		IF(bCount <= rCount) THEN 
			LEAVE myloop;
		END IF; 
		SET i=i-1;
   END WHILE;
	RETURN price;
END//
DELIMITER ;

-- Дамп структуры для таблица sklad.configs
CREATE TABLE IF NOT EXISTS `configs` (
  `configId` int(11) NOT NULL AUTO_INCREMENT,
  `configName` varchar(50) NOT NULL,
  `configValue` varchar(250) DEFAULT NULL,
  PRIMARY KEY (`configId`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.configs: ~2 rows (приблизительно)
/*!40000 ALTER TABLE `configs` DISABLE KEYS */;
INSERT INTO `configs` (`configId`, `configName`, `configValue`) VALUES
	(1, 'openday', '0'),
	(2, 'currentFaktura', '0');
/*!40000 ALTER TABLE `configs` ENABLE KEYS */;

-- Дамп структуры для таблица sklad.contragent
CREATE TABLE IF NOT EXISTS `contragent` (
  `contragentId` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `address` varchar(250) DEFAULT NULL,
  `bankAccount` varchar(50) DEFAULT NULL,
  `person` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`contragentId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.contragent: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `contragent` DISABLE KEYS */;
/*!40000 ALTER TABLE `contragent` ENABLE KEYS */;

-- Дамп структуры для представление sklad.curbalance
-- Создание временной таблицы для обработки ошибок зависимостей представлений
CREATE TABLE `curbalance` (
	`prodId` INT(11) NULL,
	`curEndCount` DOUBLE NULL,
	`endCount` VARCHAR(41) NULL COLLATE 'utf8mb4_general_ci',
	`productId` INT(11) NOT NULL,
	`name` VARCHAR(150) NULL COLLATE 'utf8_general_ci',
	`measureId` INT(11) NULL,
	`barcode` VARCHAR(50) NULL COLLATE 'utf8_general_ci',
	`status` INT(11) NOT NULL,
	`price` INT(11) NULL,
	`pack` INT(11) NOT NULL
) ENGINE=MyISAM;

-- Дамп структуры для таблица sklad.debt
CREATE TABLE IF NOT EXISTS `debt` (
  `debtId` int(11) NOT NULL AUTO_INCREMENT,
  `expenseId` int(11) NOT NULL,
  `payDate` date DEFAULT NULL,
  `summ` int(11) DEFAULT NULL,
  `terminal` int(11) DEFAULT NULL,
  `transfer` int(11) DEFAULT NULL,
  `cash` int(11) DEFAULT NULL,
  `IsPaid` int(11) DEFAULT NULL,
  `comment` varchar(300) DEFAULT NULL,
  PRIMARY KEY (`debtId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.debt: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `debt` DISABLE KEYS */;
/*!40000 ALTER TABLE `debt` ENABLE KEYS */;

-- Дамп структуры для представление sklad.debtview
-- Создание временной таблицы для обработки ошибок зависимостей представлений
CREATE TABLE `debtview` (
	`expenseDate` DATETIME NULL,
	`comment` VARCHAR(100) NOT NULL COLLATE 'utf8_general_ci',
	`expSum` INT(11) NULL
) ENGINE=MyISAM;

-- Дамп структуры для таблица sklad.expense
CREATE TABLE IF NOT EXISTS `expense` (
  `expenseId` int(11) NOT NULL AUTO_INCREMENT,
  `expenseDate` datetime DEFAULT NULL,
  `debt` int(11) NOT NULL,
  `comment` varchar(100) NOT NULL,
  `contragentId` int(11) DEFAULT NULL,
  `off` int(11) NOT NULL,
  `expType` int(11) DEFAULT NULL,
  `transfer` int(11) DEFAULT '0',
  `inCash` int(11) DEFAULT '0',
  `terminal` int(11) DEFAULT '0',
  `expSum` int(11) DEFAULT NULL,
  `status` int(11) NOT NULL,
  `userID` int(11) DEFAULT NULL,
  PRIMARY KEY (`expenseId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.expense: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `expense` DISABLE KEYS */;
/*!40000 ALTER TABLE `expense` ENABLE KEYS */;

-- Дамп структуры для процедура sklad.ExpenseTrigger
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `ExpenseTrigger`(IN `id` INT)
    COMMENT 'Процедура при оплате счета'
BEGIN

  	DECLARE done INT DEFAULT 0;
	DECLARE bCount float;
	DECLARE orderCount float;
	DECLARE prodsID int;
	DECLARE expeSum float;
	DECLARE termSum float ;
	DECLARE cur1 CURSOR FOR SELECT o.prodId,o.packCount FROM orders o where o.expenseId = id;
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
	
	OPEN cur1;
		REPEAT
			FETCH cur1 INTO prodsID, orderCount;
			IF NOT done THEN
				SET bCount = prodBalance(prodsID);
				UPDATE balance	SET endCount = (bCount - orderCount) where prodId = prodsID;
			END IF;
		UNTIL done END REPEAT;
	CLOSE cur1;
	
	SET expeSum = (SELECT ex.expSum FROM expense ex where ex.expenseId = id);
	SET termSum = (SELECT ex.terminal FROM expense ex where ex.expenseId = id);
	
	UPDATE info SET proceed = (proceed + expeSum), nal = (nal + (expeSum - termSum)), terminal = (terminal + termSum) where Dates = date(now());
		
END//
DELIMITER ;

-- Дамп структуры для представление sklad.expenseview
-- Создание временной таблицы для обработки ошибок зависимостей представлений
CREATE TABLE `expenseview` (
	`expenseDate` DATE NULL,
	`name` VARCHAR(150) NULL COLLATE 'utf8_general_ci',
	`pack` INT(11) NOT NULL,
	`count` DOUBLE NULL,
	`measureId` INT(11) NULL
) ENGINE=MyISAM;

-- Дамп структуры для таблица sklad.faktura
CREATE TABLE IF NOT EXISTS `faktura` (
  `fakturaId` int(11) NOT NULL AUTO_INCREMENT,
  `fakturaDate` datetime DEFAULT NULL,
  `userId` int(11) DEFAULT NULL,
  `orgId` int(11) DEFAULT NULL,
  `providerId` int(11) DEFAULT NULL,
  `isClosed` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`fakturaId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.faktura: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `faktura` DISABLE KEYS */;
/*!40000 ALTER TABLE `faktura` ENABLE KEYS */;

-- Дамп структуры для процедура sklad.FakturaTrigger
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `FakturaTrigger`(IN `id` INT)
    COMMENT 'Процедура при оплате счета'
BEGIN

	/*DECLARE done INT DEFAULT 0;
	DECLARE bCount float;
	DECLARE realizeCount float;
	DECLARE prodsID int;
	DECLARE cur1 CURSOR FOR SELECT r.prodId,r.count FROM realize r where r.fakturaId = id;
	DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
	
	OPEN cur1;
	
	REPEAT
		FETCH cur1 INTO prodsID, realizeCount;
		IF NOT done THEN
			SET bCount = prodBalance(prodsID);
			UPDATE balance	SET endCount = (bCount + realizeCount) where balanceDate=date(now()) and prodId = prodsID;
		END IF;
	UNTIL done END REPEAT;
	
	CLOSE cur1;
*/
END//
DELIMITER ;

-- Дамп структуры для функция sklad.getPrice
DELIMITER //
CREATE DEFINER=`root`@`localhost` FUNCTION `getPrice`(`id` INT) RETURNS float
    DETERMINISTIC
    COMMENT 'Получение цены продукта на основе остатка продукта'
BEGIN
	
	DECLARE lastDate Date;
	DECLARE prodPrice Float;
	#SET LastDate = (select balanceDate from balance order by balanceDate DESC limit 1);
/*	IF workMode = 0 THEN 
		SET lastDate = (select balanceDate from balanceList where prodId = id group by balanceDate order by balanceDate desc limit 1);
		IF lastDate is not null THEN 
			SET prodPrice = checkRealize(id, prodBalance(id));
		ELSE */
			SET prodPrice = (select price from product where productId = id limit 1);
/*		END IF;
	ELSEIF workMode = 1 THEN
		SET prodPrice = (select price from product where productId = id limit 1);
	END IF;*/
	return prodPrice;
END//
DELIMITER ;

-- Дамп структуры для таблица sklad.hotkeys
CREATE TABLE IF NOT EXISTS `hotkeys` (
  `hotKeysId` int(11) NOT NULL AUTO_INCREMENT,
  `prodId` varchar(50) DEFAULT NULL,
  `btnId` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`hotKeysId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.hotkeys: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `hotkeys` DISABLE KEYS */;
/*!40000 ALTER TABLE `hotkeys` ENABLE KEYS */;

-- Дамп структуры для таблица sklad.hotkeyslibra
CREATE TABLE IF NOT EXISTS `hotkeyslibra` (
  `hotKeysLibraId` int(11) NOT NULL AUTO_INCREMENT,
  `prodLibraId` varchar(50) DEFAULT NULL,
  `btnLibraId` varchar(50) DEFAULT NULL,
  `libraId` int(11) DEFAULT NULL,
  PRIMARY KEY (`hotKeysLibraId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.hotkeyslibra: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `hotkeyslibra` DISABLE KEYS */;
/*!40000 ALTER TABLE `hotkeyslibra` ENABLE KEYS */;

-- Дамп структуры для таблица sklad.info
CREATE TABLE IF NOT EXISTS `info` (
  `infoId` int(11) NOT NULL AUTO_INCREMENT,
  `Dates` date DEFAULT NULL,
  `proceed` int(11) DEFAULT NULL,
  `nal` int(11) DEFAULT NULL,
  `back` int(11) DEFAULT NULL,
  `terminal` int(11) DEFAULT NULL,
  `userId` int(11) DEFAULT '0',
  PRIMARY KEY (`infoId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.info: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `info` DISABLE KEYS */;
/*!40000 ALTER TABLE `info` ENABLE KEYS */;

-- Дамп структуры для таблица sklad.libra
CREATE TABLE IF NOT EXISTS `libra` (
  `libraId` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL,
  `ipAddress` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`libraId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.libra: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `libra` DISABLE KEYS */;
/*!40000 ALTER TABLE `libra` ENABLE KEYS */;

-- Дамп структуры для таблица sklad.measure
CREATE TABLE IF NOT EXISTS `measure` (
  `measureId` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) DEFAULT NULL,
  `type` int(11) NOT NULL,
  `status` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`measureId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.measure: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `measure` DISABLE KEYS */;
/*!40000 ALTER TABLE `measure` ENABLE KEYS */;

-- Дамп структуры для таблица sklad.orders
CREATE TABLE IF NOT EXISTS `orders` (
  `orderId` int(11) NOT NULL AUTO_INCREMENT,
  `expenseId` int(11) NOT NULL,
  `prodId` int(11) NOT NULL,
  `count` float NOT NULL,
  `packCount` float DEFAULT NULL,
  `orderSumm` float DEFAULT NULL,
  PRIMARY KEY (`orderId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.orders: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `orders` DISABLE KEYS */;
/*!40000 ALTER TABLE `orders` ENABLE KEYS */;

-- Дамп структуры для представление sklad.ordersview
-- Создание временной таблицы для обработки ошибок зависимостей представлений
CREATE TABLE `ordersview` (
	`expenseId` INT(11) NOT NULL,
	`name` VARCHAR(150) NULL COLLATE 'utf8_general_ci',
	`expenseDate` DATETIME NULL,
	`cnt` FLOAT NULL,
	`orderSumm` FLOAT NULL
) ENGINE=MyISAM;

-- Дамп структуры для функция sklad.prodBalance
DELIMITER //
CREATE DEFINER=`root`@`localhost` FUNCTION `prodBalance`(`id` INT) RETURNS float
    DETERMINISTIC
    COMMENT 'Высчитывание текущего остатка продукта'
BEGIN
	DECLARE prodID INT;
	DECLARE eCount FLOAT;
	DECLARE cEndCount FLOAT;
	DECLARE realizes INT;
	DECLARE i INT;
	DECLARE checks date;
	DECLARE LastDate date;
	DECLARE back INT;
	DECLARE bCnt int DEFAULT(0);
	DECLARE result float DEFAULT(null);
	DECLARE cDate date DEFAULT(date(now()));
	
	SET i = (select productId from product order by productId DESC limit 1);
	SET checks = (select balanceDate from balanceList where balanceDate = date(now()) limit 1);
	SET LastDate = (select balanceDate from balanceList order by balanceDate DESC limit 1);
	SET BCnt = (select count(*) from balanceList );
	
	IF id = 0 THEN
		IF (bCnt != 0) THEN
			IF (LastDate < cDAte ) THEN
		
				WHILE i > 0 DO
				
					SET prodID = (select productId from product where productId = i);
					IF(prodID is not NULL) THEN
						
						# Начальный остаток продукта
						#SET cEndCount = (select b.curEndCount from balance b where b.prodId = prodID and b.balanceDate = LastDate order by balanceDate DESC limit 1);
						#IF(cEndCount is NULL) THEN		
							SET eCount = (select b.endCount from balance b where b.prodId = i and b.balanceDate = '2000-01-01' limit 1);
						#ELSE		
						#	SET eCount = cEndCount;
						#END IF;
						
						# Insert в таблицу баланс
						insert into balanceList (`balanceDate`,`prodId`,`endCount`) values(date(now()),prodID,eCount);
						IF eCount <= 0 THEN
							update product set expiry = null where expiry < CONCAT(CONCAT(year(now()) ,'-',month(now())),'-','01') and productId = prodID;
						END IF;
					END IF;
					
					SET i=i-1;
				END WHILE;
				insert into info (`Dates`,`proceed`,`nal`,`back`,`terminal`) values(date(now()),0,0,0,0);
			END IF;
		ELSE
				WHILE i > 0 DO
				
					SET prodID = (select productId from product where productId = i);
					IF(prodID is not NULL) THEN
					
						#Приход продукта
						SET eCount = (select sum(r.count) from faktura f join realize r on r.fakturaId = f.fakturaId where r.prodId = prodID and date(f.fakturaDate) = date(now()) limit 1);
						IF (eCOunt is null) THEN 
							SET eCount = 0;
						END IF;
					
						# Insert в таблицу баланс
						insert into balanceList (`balanceDate`,`prodId`,`endCount`) values(date(now()),prodID,eCount);
						insert into balance (`balanceDate`,`prodId`,`endCount`) values('2000-01-01',prodID,eCount);
						
					END IF;
					
					SET i=i-1;
			   END WHILE;
				insert into info (`Dates`,`proceed`,`nal`,`back`,`terminal`) values(date(now()),0,0,0,0);			
		END IF;	 
	END IF;
	IF ( LastDate > cDAte ) THEN
		SET result = 0;
	ELSE
		SET result = (select b.endCount from balance b where b.balanceDate = '2000-01-01' and b.prodId = id limit 1);
	END IF;
	return result;
		
END//
DELIMITER ;

-- Дамп структуры для процедура sklad.ProdBalanceFrom
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `ProdBalanceFrom`(IN `id` INT, IN `bDate` DATE)
BEGIN
DECLARE prodID INT;
	DECLARE eCount float;
	DECLARE eCountTemp float;
	DECLARE cEndCount float;
	Declare isBegin Tinyint;
	DECLARE realizes INT;
	DECLARE i INT;
	DECLARE BeforeDate date;
	DECLARE LastDate date;
	DECLARE tDate date;
	DECLARE back INT;
	DECLARE bCnt int DEFAULT(0);
	DECLARE result float DEFAULT(null);
	DECLARE cDate date DEFAULT(date(now()));

  SET eCountTemp = NULL;
	SET i = (select productId from product order by productId DESC limit 1);

	SET LastDate = bDate;
	SET BCnt = (select count(*) from balanceList );

	#Определение даты
  SET BeforeDate = (select balanceDate from balancelist where prodId = id order by balanceDate asc limit 1);
	#SET tDate = (select expenseDate from expense order by expenseDate asc limit 1);
 IF BeforeDate IS NULL THEN SET BeforeDate = bDate;  END IF;

  IF BeforeDate >= bDate THEN SET isBegin = 1;
	ELSE
		set isBegin = 0;

	END IF;
	IF id <> 0 THEN

				#WHILE i > 0 DO
				
				IF isBegin = 1 THEN
					SET prodID = (select productId from product where productId = id);
					IF(prodID is not NULL) THEN
					
						#Приход продукта
						SET eCount = (select sum(r.count) from faktura f join realize r on r.fakturaId = f.fakturaId where r.prodId = prodID and date(f.fakturaDate) <= bDate limit 1);
						IF (eCOunt is null) THEN
							SET eCount = 0;
						END IF;
						
						#расход продукта
						SET eCountTemp = (select sum(o.packCount) from expense as e join orders as o on e.expenseId = o.expenseId where o.prodId = prodID and  date(e.expenseDate) <= bDate  and e.expType = 0  limit 1);
						IF (eCountTemp is null) THEN
							SET eCountTemp = 0;
						END IF;
						SET eCount = eCount - eCountTemp;
						
						#Возврат товара
						SET eCountTemp = (select sum(o.packCount) from expense as e join orders as o on e.expenseId = o.expenseId where o.prodId = prodID and  date(e.expenseDate) <= bDate  and e.expType = 1  limit 1);
						IF (eCountTemp is null) THEN
							SET eCountTemp = 0;
						END IF;
						SET eCount = eCount + eCountTemp;
						
						
						#Списание товара					
						SET eCountTemp = (select sum(o.packCount) from expense as e join orders as o on e.expenseId = o.expenseId where o.prodId = prodID and  date(e.expenseDate) <= bDate  and e.expType = 3  limit 1);
						IF (eCountTemp is null) THEN
							SET eCountTemp = 0;
						END IF;
						SET eCount = eCount - eCountTemp;
						
             delete from `balancelist` where `balancelist`.`prodId` = prodID and balanceDate =  adddate(bDate, 1);

						# Insert в таблицу баланс
						insert into balanceList (`balanceDate`,`prodId`,`endCount`) values(adddate(bDate, 1),prodID,eCount);
						#update into balance (`balanceDate`,`prodId`,`endCount`) values('2000-01-01',prodID,eCount);

					END IF;
				ELSE 
				SET BeforeDate = bDate - interval 1 DAY;
				

					SET prodID = (select productId from product where productId = id);
          SET BeforeDate = bDate - interval 1 DAY;
          SET tDate = NULL;
					WHILE tDate IS NULL DO

           SET tDate = (select balanceDate from balancelist as bl where bl.prodId = prodID and bl.balanceDate = BeforeDate);
						IF tDate IS NULL THEN
              SET BeforeDate = BeforeDate - interval 1 DAY;
            ELSE
              SET eCountTemp = (select endCount from balancelist as bl where bl.prodId = prodID and bl.balanceDate = BeforeDate);
              IF eCount IS NULL THEN SET eCountTemp = 0; END IF;
            END IF;
					END WHILE;
					
					IF prodID <> NULL THEN
					
						#Приход продукта
						SET eCount = (select sum(r.count) from faktura f join realize r on r.fakturaId = f.fakturaId where r.prodId = prodID and date(f.fakturaDate) = bDate limit 1);
						IF (eCOunt is null) THEN 
							SET eCount = 0;
						END IF;
						SET eCount = eCountTemp + eCount;
						#расход продукта						
						SET eCountTemp = (select sum(r.count) from expense as e join orders as o on e.expenseId = o.expenseId where o.prodId = prodID and  date(e.expenseDate) = bDate  and e.expType = 0  limit 1);
						IF (eCountTemp is null) THEN 
							SET eCountTemp = 0;
						END IF;
						SET eCount = eCount - eCountTemp;
						
						#Возврат товара
						SET eCountTemp = (select sum(r.count) from expense as e join orders as o on e.expenseId = o.expenseId where o.prodId = prodID and  date(e.expenseDate) = bDate  and e.expType = 1  limit 1);
						IF (eCountTemp is null) THEN 
							SET eCountTemp = 0;
						END IF;
						SET eCount = eCount + eCountTemp;
						
						
						#Списание товара					
						SET eCountTemp = (select sum(r.count) from expense as e join orders as o on e.expenseId = o.expenseId where o.prodId = prodID and  date(e.expenseDate) = bDate  and e.expType = 3  limit 1);
						IF (eCountTemp is null) THEN 
							SET eCountTemp = 0;
						END IF;
						SET eCount = eCount - eCountTemp;

						# Insert в таблицу баланс
						insert into balanceList (`balanceDate`,`prodId`,`endCount`) values(bDate,prodID,eCount);
						insert into balance (`balanceDate`,`prodId`,`endCount`) values('2000-01-01',prodID,eCount);
				END IF;
				#	SET i=i-1;
			   #END WHILE;
				#insert into info (`Dates`,`proceed`,`nal`,`back`,`terminal`) values(bDate),0,0,0,0);			
		END IF;	 
	END IF;
	
	
END//
DELIMITER ;

-- Дамп структуры для таблица sklad.product
CREATE TABLE IF NOT EXISTS `product` (
  `productId` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(150) DEFAULT NULL,
  `measureId` int(11) DEFAULT NULL,
  `barcode` varchar(50) DEFAULT NULL,
  `status` int(11) NOT NULL,
  `price` int(11) DEFAULT NULL,
  `pack` int(11) NOT NULL,
  `BalanceT` int(11) DEFAULT NULL,
  `expiry` varchar(50) DEFAULT NULL,
  `providerId` int(11) DEFAULT NULL,
  PRIMARY KEY (`productId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.product: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `product` DISABLE KEYS */;
/*!40000 ALTER TABLE `product` ENABLE KEYS */;

-- Дамп структуры для представление sklad.productview
-- Создание временной таблицы для обработки ошибок зависимостей представлений
CREATE TABLE `productview` (
	`productId` INT(11) NOT NULL,
	`name` VARCHAR(150) NULL COLLATE 'utf8_general_ci',
	`providerId` INT(11) NULL,
	`price` INT(11) NULL,
	`barcode` VARCHAR(50) NULL COLLATE 'utf8_general_ci',
	`expiry` VARCHAR(50) NULL COLLATE 'utf8_general_ci',
	`balanceDate` DATE NULL,
	`endCount` FLOAT NULL
) ENGINE=MyISAM;

-- Дамп структуры для таблица sklad.provider
CREATE TABLE IF NOT EXISTS `provider` (
  `providerId` int(11) NOT NULL AUTO_INCREMENT,
  `orgName` varchar(100) DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`providerId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.provider: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `provider` DISABLE KEYS */;
/*!40000 ALTER TABLE `provider` ENABLE KEYS */;

-- Дамп структуры для таблица sklad.realize
CREATE TABLE IF NOT EXISTS `realize` (
  `realizeId` int(11) NOT NULL AUTO_INCREMENT,
  `fakturaId` int(11) DEFAULT NULL,
  `prodId` int(11) DEFAULT NULL,
  `count` float DEFAULT NULL,
  `price` float DEFAULT NULL,
  `soldPrice` int(11) DEFAULT NULL,
  `expiryDate` date DEFAULT NULL,
  PRIMARY KEY (`realizeId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT=' ';

-- Дамп данных таблицы sklad.realize: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `realize` DISABLE KEYS */;
/*!40000 ALTER TABLE `realize` ENABLE KEYS */;

-- Дамп структуры для представление sklad.realizeview
-- Создание временной таблицы для обработки ошибок зависимостей представлений
CREATE TABLE `realizeview` (
	`realizeId` INT(11) NOT NULL,
	`fakturaId` INT(11) NOT NULL,
	`name` VARCHAR(150) NULL COLLATE 'utf8_general_ci',
	`barcode` VARCHAR(50) NULL COLLATE 'utf8_general_ci',
	`providerId` INT(11) NULL,
	`fakturaDate` DATE NULL,
	`price` DOUBLE(17,0) NULL,
	`count` VARCHAR(41) NULL COLLATE 'utf8mb4_general_ci',
	`productId` INT(11) NOT NULL,
	`soldPrice` INT(11) NULL,
	`expiryDate` DATE NULL,
	`fakturaPrice` FLOAT NULL
) ENGINE=MyISAM;

-- Дамп структуры для процедура sklad.SetBalance
DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `SetBalance`(IN `id` INT)
BEGIN
DECLARE prodID INT;
	DECLARE eCount float;
	DECLARE eCountTemp float;

	DECLARE back INT;
	DECLARE bCnt int DEFAULT(0);
	DECLARE result float DEFAULT(null);
	DECLARE cDate date DEFAULT(date(now()));

  


	IF id <> 0 THEN

				#WHILE i > 0 DO
				
				
					SET prodID = (select productId from product where productId = id);
					IF(prodID is not NULL) THEN
					
						#Приход продукта
						SET eCount = (select sum(r.count) from faktura f join realize r on r.fakturaId = f.fakturaId where r.prodId = prodID and date(f.fakturaDate) <= cDate limit 1);
						IF (eCOunt is null) THEN
							SET eCount = 0;
						END IF;
						
						#расход продукта
						SET eCountTemp = (select sum(o.packCount) from expense as e join orders as o on e.expenseId = o.expenseId where o.prodId = prodID and  date(e.expenseDate) <= cDate  and e.expType = 0  limit 1);
						IF (eCountTemp is null) THEN
							SET eCountTemp = 0;
						END IF;
						SET eCount = eCount - eCountTemp;
						
						#Возврат товара
						SET eCountTemp = (select sum(o.packCount) from expense as e join orders as o on e.expenseId = o.expenseId where o.prodId = prodID and  date(e.expenseDate) <= cDate  and e.expType = 1  limit 1);
						IF (eCountTemp is null) THEN
							SET eCountTemp = 0;
						END IF;
						SET eCount = eCount + eCountTemp;
						
						
						#Списание товара					
						SET eCountTemp = (select sum(o.packCount) from expense as e join orders as o on e.expenseId = o.expenseId where o.prodId = prodID and  date(e.expenseDate) <= cDate  and e.expType = 3  limit 1);
						IF (eCountTemp is null) THEN
							SET eCountTemp = 0;
						END IF;
						SET eCount = eCount - eCountTemp;
						
						update balance set endCount = eCount where balance.prodId = prodID; 
            END IF;
						

				
				
	END IF;
	
	
END//
DELIMITER ;

-- Дамп структуры для таблица sklad.transfer
CREATE TABLE IF NOT EXISTS `transfer` (
  `transferId` int(11) NOT NULL AUTO_INCREMENT,
  `summ` int(11) NOT NULL,
  `transferType` int(11) NOT NULL COMMENT 'type: 1- in cash, 2 - terminal, 3 - transfer form',
  `contragentId` int(11) NOT NULL,
  `expenseId` int(11) DEFAULT NULL,
  PRIMARY KEY (`transferId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.transfer: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `transfer` DISABLE KEYS */;
/*!40000 ALTER TABLE `transfer` ENABLE KEYS */;

-- Дамп структуры для таблица sklad.user
CREATE TABLE IF NOT EXISTS `user` (
  `IDUser` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(25) NOT NULL,
  `password` varchar(255) NOT NULL,
  `email` varchar(25) DEFAULT NULL,
  `IDUserType` int(11) DEFAULT NULL,
  `phone` varchar(15) DEFAULT NULL,
  `ban` tinyint(4) NOT NULL DEFAULT '0',
  `role` varchar(255) NOT NULL,
  `IsActive` tinyint(4) DEFAULT NULL,
  `name` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`IDUser`),
  KEY `usertype` (`IDUserType`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.user: ~5 rows (приблизительно)
/*!40000 ALTER TABLE `user` DISABLE KEYS */;
INSERT INTO `user` (`IDUser`, `username`, `password`, `email`, `IDUserType`, `phone`, `ban`, `role`, `IsActive`, `name`) VALUES
	(1, 'admin', '181c27e9fd350da69575904879131165', 'admin@admin.ru', 0, NULL, 0, 'admin', 0, NULL),
	(6, 'user', '820526b77f0ca1bfcdafb92a7bf1e998', 'asd@asde.ru', 0, NULL, 0, 'user', 0, NULL),
	(7, 'Kamola Hakimova', '207761567b4621904aba62bb1916578f', '', 0, NULL, 0, 'user', 0, NULL),
	(9, 'Farrux', '1f32aa4c9a1d2ea010adcf2348166a04', NULL, 0, NULL, 0, 'user', 0, NULL),
	(10, 'Muhriddin', '113969485f92c6e5c66b9e503222d7fd', NULL, NULL, NULL, 0, 'user', NULL, NULL);
/*!40000 ALTER TABLE `user` ENABLE KEYS */;

-- Дамп структуры для таблица sklad.usertype
CREATE TABLE IF NOT EXISTS `usertype` (
  `IDUserType` int(11) NOT NULL AUTO_INCREMENT,
  `UserType` varchar(25) NOT NULL,
  PRIMARY KEY (`IDUserType`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы sklad.usertype: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `usertype` DISABLE KEYS */;
/*!40000 ALTER TABLE `usertype` ENABLE KEYS */;

-- Дамп структуры для представление sklad.backrealizeview
-- Удаление временной таблицы и создание окончательной структуры представления
DROP TABLE IF EXISTS `backrealizeview`;
CREATE ALGORITHM=TEMPTABLE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `backrealizeview` AS select `r`.`backRealizeId` AS `backRealizeId`,`f`.`backFakturaId` AS `backFakturaId`,`p`.`name` AS `name`,cast(`f`.`fakturaDate` as date) AS `fakturaDate`,round((`r`.`count` * (select (case when (`p`.`pack` <> 0) then round((`r`.`price` / `p`.`pack`),2) else `r`.`price` end) AS `price` from `product` `p` where (`p`.`productId` = `r`.`prodId`) limit 1)),0) AS `price`,(case when (`p`.`pack` <> 0) then concat(floor((`r`.`count` / `p`.`pack`)),'/',(`r`.`count` - (floor((`r`.`count` / `p`.`pack`)) * `p`.`pack`))) else `r`.`count` end) AS `count`,`p`.`productId` AS `productId` from ((`backfaktura` `f` join `backrealize` `r` on((`r`.`backFakturaId` = `f`.`backFakturaId`))) join `product` `p` on((`p`.`productId` = `r`.`prodId`))) ;

-- Дамп структуры для представление sklad.backview
-- Удаление временной таблицы и создание окончательной структуры представления
DROP TABLE IF EXISTS `backview`;
CREATE ALGORITHM=TEMPTABLE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `backview` AS select `e`.`expenseDate` AS `expenseDate`,`o`.`packCount` AS `count`,`p`.`name` AS `name`,`p`.`pack` AS `pack` from ((`expense` `e` join `orders` `o` on((`o`.`expenseId` = `e`.`expenseId`))) join `product` `p` on((`p`.`productId` = `o`.`prodId`))) where ((`e`.`debt` <> 1) and (`e`.`status` <> 1) and (`e`.`expType` <> 0)) group by `e`.`expenseDate` ;

-- Дамп структуры для представление sklad.balanceview
-- Удаление временной таблицы и создание окончательной структуры представления
DROP TABLE IF EXISTS `balanceview`;
CREATE ALGORITHM=TEMPTABLE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `balanceview` AS select `b`.`balanceId` AS `balanceId`,`b`.`balanceDate` AS `balanceDate`,`b`.`prodId` AS `prodId`,
round(`b`.`endCount` * (select (case when (`p`.`pack` <> 0) then floor((`p`.`price` / `p`.`pack`)) 
else `p`.`price` end) AS `price` from `product` `p` where (`p`.`productId` = `b`.`prodId`) limit 1)) AS `curEndCount`,
`p`.`price` AS `price`,
(case when p.measureId=1 then round(`b`.`endCount`, 3) else b.endCount end) AS `endCount`,`p`.`productId` AS `productId`,`p`.`name` AS `name`,`p`.`measureId` AS `measureId`,`p`.`barcode` AS `barcode`,`p`.`status` AS `status`,`p`.`pack` AS `pack` 

from (`balance` `b` join `product` `p` on((`p`.`productId` = `b`.`prodId`))) where (`b`.`endCount` <> 0) order by `b`.`prodId` ;

-- Дамп структуры для представление sklad.curbalance
-- Удаление временной таблицы и создание окончательной структуры представления
DROP TABLE IF EXISTS `curbalance`;
CREATE ALGORITHM=TEMPTABLE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `curbalance` AS select `b`.`prodId` AS `prodId`,(`prodBalance`(`b`.`prodId`,(select `balance`.`balanceDate` from `balance` order by `balance`.`balanceDate` desc limit 1)) * (select (case when (`p`.`pack` <> 0) then floor((`p`.`price` / `p`.`pack`)) else `p`.`price` end) AS `price` from `product` `p` where (`p`.`productId` = `b`.`prodId`) limit 1)) AS `curEndCount`,(case when (`p`.`pack` <> 0) then concat(floor((`prodBalance`(`b`.`prodId`,(select `balance`.`balanceDate` from `balance` order by `balance`.`balanceDate` desc limit 1)) / `p`.`pack`)),'/',(`prodBalance`(`b`.`prodId`,(select `balance`.`balanceDate` from `balance` order by `balance`.`balanceDate` desc limit 1)) - (floor((`b`.`endCount` / `p`.`pack`)) * `p`.`pack`))) else convert(`prodBalance`(`b`.`prodId`,(select `balance`.`balanceDate` from `balance` order by `balance`.`balanceDate` desc limit 1)) using utf8mb4) end) AS `endCount`,`p`.`productId` AS `productId`,`p`.`name` AS `name`,`p`.`measureId` AS `measureId`,`p`.`barcode` AS `barcode`,`p`.`status` AS `status`,`p`.`price` AS `price`,`p`.`pack` AS `pack` from (`balance` `b` join `product` `p` on((`p`.`productId` = `b`.`prodId`))) where (`b`.`balanceDate` = (select `balance`.`balanceDate` from `balance` order by `balance`.`balanceDate` desc limit 1)) order by `b`.`prodId` ;

-- Дамп структуры для представление sklad.debtview
-- Удаление временной таблицы и создание окончательной структуры представления
DROP TABLE IF EXISTS `debtview`;
CREATE ALGORITHM=TEMPTABLE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `debtview` AS select `e`.`expenseDate` AS `expenseDate`,`e`.`comment` AS `comment`,`e`.`expSum` AS `expSum` from `expense` `e` where ((`e`.`debt` = 1) and (`e`.`expType` <> 1)) ;

-- Дамп структуры для представление sklad.expenseview
-- Удаление временной таблицы и создание окончательной структуры представления
DROP TABLE IF EXISTS `expenseview`;
CREATE ALGORITHM=TEMPTABLE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `expenseview` AS select 
cast(`e`.`expenseDate` as date) AS `expenseDate`,
`p`.`name` AS `name`,
`p`.`pack` AS `pack`,
(case when p.measureId=2 then sum(`o`.`packCount`) else Round(sum(`o`.`packCount`), 3) end) AS `count`, 
p.measureId
 from ((`expense` `e` join `orders` `o` on((`o`.`expenseId` = `e`.`expenseId`))) join `product` `p` 
on((`p`.`productId` = `o`.`prodId`))) where ((`e`.`debt` <> 1) and (`e`.`status` <> 1) and (`e`.`expType` <> 1)) group by cast(`e`.`expenseDate` as date),`o`.`prodId` ;

-- Дамп структуры для представление sklad.ordersview
-- Удаление временной таблицы и создание окончательной структуры представления
DROP TABLE IF EXISTS `ordersview`;
CREATE ALGORITHM=TEMPTABLE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `ordersview` AS select `o`.`expenseId` AS `expenseId`,`p`.`name` AS `name`,`ex`.`expenseDate` AS `expenseDate`,`o`.`packCount` AS `cnt`,`o`.`orderSumm` AS `orderSumm` from ((`orders` `o` join `product` `p` on((`p`.`productId` = `o`.`prodId`))) join `expense` `ex` on((`ex`.`expenseId` = `o`.`expenseId`))) ;

-- Дамп структуры для представление sklad.productview
-- Удаление временной таблицы и создание окончательной структуры представления
DROP TABLE IF EXISTS `productview`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `productview` AS select `p`.`productId` AS `productId`,
`p`.`name` AS `name`,
`p`.`providerId` AS `providerId`,
`p`.`price` AS `price`,
`p`.`barcode` AS `barcode`,
`p`.`expiry` AS `expiry`,
`b`.`balanceDate` AS `balanceDate`,
`b`.`endCount` AS `endCount` from (`product` `p` left join `balance` `b` on((`p`.`productId` = `b`.`prodId`))) where (`b`.`balanceDate` = '2000-01-01') ;

-- Дамп структуры для представление sklad.realizeview
-- Удаление временной таблицы и создание окончательной структуры представления
DROP TABLE IF EXISTS `realizeview`;
CREATE ALGORITHM=TEMPTABLE DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `realizeview` AS select `r`.`realizeId` AS `realizeId`,`f`.`fakturaId` AS `fakturaId`,`p`.`name` AS `name`,`p`.barcode AS `barcode`,f.providerId,
cast(`f`.`fakturaDate` as date) AS `fakturaDate`,round((`r`.`count` * (select (case when (`p`.`pack` <> 0) then round((`r`.`price` / `p`.`pack`),2) else `r`.`price` end) AS `price`  

from `product` `p` where (`p`.`productId` = `r`.`prodId`) limit 1)),0) AS `price`,
(case when (`p`.`pack` <> 0) then concat(floor((`r`.`count` / `p`.`pack`)),'/',(`r`.`count` - (floor((`r`.`count` / `p`.`pack`)) * `p`.`pack`))) else `r`.`count` end) AS `count`,`p`.`productId` AS `productId`,`r`.`soldPrice` AS `soldPrice`,`r`.`expiryDate` AS `expiryDate`, r.price as fakturaPrice  from ((`faktura` `f` join `realize` `r` on((`r`.`fakturaId` = `f`.`fakturaId`))) join `product` `p` on((`p`.`productId` = `r`.`prodId`))) ;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
