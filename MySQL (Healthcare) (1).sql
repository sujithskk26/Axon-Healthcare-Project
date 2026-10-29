use patientmgnt;
-- ====================

ALTER TABLE patient
ADD COLUMN PatientName VARCHAR(255);

UPDATE patient
SET PatientName = CONCAT(FirstName, ' ', LastName);
 -- ==============================

SET SQL_SAFE_UPDATES = 0;
UPDATE visit
SET
    Year = YEAR(`VisitDate`),
    Month = MONTHNAME(`VisitDate`),
    Day = DAYNAME(`VisitDate`),
    Quarter = CONCAT('Q-', QUARTER(`VisitDate`))
WHERE VisitID IS NOT NULL;
-- ===============
SELECT
    VisitID,
    VisitDate,
    Year,
    Month,
    Day,
    Quarter
FROM visit;
-- ============Data Count Validation=================
SELECT COUNT(*) FROM Patient;
SELECT COUNT(*) FROM Visit;
SELECT COUNT(*) FROM Treatments;
SELECT COUNT(*) FROM LabResult;

-- ===========Data Completeness Check====================

SELECT * FROM Patient WHERE FirstName IS NULL OR LastName IS NULL;
SELECT * FROM Visit WHERE VisitType IS NULL OR VisitDate IS NULL;
SELECT * FROM Treatments WHERE TreatmentName IS NULL OR Status IS NULL;
SELECT * FROM LabResult WHERE TestName IS NULL OR Result IS NULL;
-- ===========Data Consistency Check=======================
SELECT v.VisitID,  p.PatientID
FROM Visit v
LEFT JOIN Patient p ON v.PatientID = p.PatientID
WHERE p.PatientID IS NULL;  -- Should return 0 rows

SELECT t.TreatmentID, t.VisitID, v.VisitID
FROM Treatment t
LEFT JOIN Visit v ON t.VisitID = v.VisitID
WHERE v.VisitID IS NULL;  -- Should return 0 rows
-- ==============Duplicate Records Check===============

SELECT PatientID, COUNT(*)
FROM Patient
GROUP BY PatientID
HAVING COUNT(*) > 1;

SELECT VisitID, COUNT(*)
FROM Visit
GROUP BY VisitID
HAVING COUNT(*) > 1;
-- ===============Dashboard Aggregation Check (KPIS)==========
-- =======Total Patient
select count(patientID) from patient; -- 10000
-- ==============total doctors =============
select count(DoctorID) from doctor; -- 1000
-- ==============total visits =============
select count(visitID) from visit; -- 10000

-- ==============Average patient age =============
SELECT AVG(Age) FROM Patient;  

SELECT AVG(TIMESTAMPDIFF(YEAR, DateOfBirth, CURDATE())) AS `Average Age`FROM patient;

-- ==============Treatment Cost Per Visit (Avg.)
SELECT ROUND(SUM(TreatmentCost),2) as `Treatment Cost` FROM Treatment; -- '3851316.26'

-- ==============Total Lab Tests Conducted
select COUNT(LabResultID) from labtest; -- 10000

-- ===============Total Pending Test Results ============
SELECT
    COUNT(*) AS `Total Pending Test Results`
FROM labtest
WHERE TestResult = 'Pending'; -- 3344
-- ==============Pending Test Result % ===============
SELECT
    ROUND(
        SUM(TestResult = 'Pending') * 100.0 / COUNT(*),
        2
    ) AS `Pending Test Result %`
FROM labtest; -- 33.44%

-- ==============`Further Testing Required %` ================
SELECT
    ROUND(
        SUM(Comments = 'Requires further testing') * 100.0 / COUNT(*),
        2
    ) AS `Further Testing Required %`
FROM labtest; -- 32.71%

-- =======Percentage of Abnormal Lab Results
SELECT
    ROUND(
        SUM(TestResult = 'Abnormal') * 100.0 / COUNT(LabResultID),
        2
    ) AS Abnormal_Percentage
FROM labtest;
-- 33.54%

-- =============Doctor Workload (Avg. Patients Per Doctor)
SELECT
    d.`Doctor Name`,
    COUNT(v.VisitID) AS `Patient Visits`
FROM doctor AS d
LEFT JOIN visit AS v
    ON v.DoctorID = d.DoctorID
GROUP BY d.`Doctor Name`
ORDER BY `Patient Visits` DESC;

-- ==========month-wise patient visits for each doctor =========
SELECT
    d.`Doctor Name`,
    YEAR(v.VisitDate) AS `Year`,
    MONTH(v.VisitDate) AS `MonthNo`,
    MONTHNAME(v.VisitDate) AS `Month`,
    COUNT(v.VisitID) AS `Patient Visits`
FROM visit AS v
JOIN doctor AS d
    ON v.DoctorID = d.DoctorID
GROUP BY
    d.`Doctor Name`,
    YEAR(v.VisitDate),
    MONTH(v.VisitDate),
    MONTHNAME(v.VisitDate)
ORDER BY
    YEAR(v.VisitDate),
    MONTH(v.VisitDate),
    `Patient Visits` DESC;
    
    -- ===========year-wise patient visits for each doctor ========
    
SELECT
    YEAR(v.VisitDate) AS `Year`,
    d.`Doctor Name`,
    COUNT(v.VisitID) AS `Patient Visits`
FROM visit AS v
JOIN doctor AS d
    ON v.DoctorID = d.DoctorID
GROUP BY
    YEAR(v.VisitDate),
    d.`Doctor Name`
ORDER BY
    `Year`,
    `Patient Visits` DESC;
 -- ==========
 SELECT
    COUNT(DISTINCT PatientID) AS `Patients Requiring Follow Up`
FROM visit
WHERE FollowUpRequired = 'Yes';
-- =================

-- ===========
SELECT
	p.PatientName,
    v.VisitDate,
    v.FollowUpRequired
FROM visit AS v
JOIN patient AS p
    ON v.PatientID = p.PatientID
WHERE v.FollowUpRequired = 'Yes'
ORDER BY v.VisitDate;
 -- ==================================
 -- =============Top 5 Diagnosed Conditions ===========
SELECT
    Diagnosis,
    COUNT(*) AS DiagnosisCount
FROM visit
WHERE Diagnosis IS NOT NULL
  AND Diagnosis <> ''
GROUP BY Diagnosis
ORDER BY DiagnosisCount DESC
LIMIT 5;

-- ==========treatment Cost monthwise==============
SELECT
    v.Month  AS Month,
    ROUND(SUM(t.TreatmentCost),2) AS TotalTreatmentCost
FROM visit v
JOIN treatment t
    ON v.VisitID = t.VisitID
GROUP BY
	v.MONTH
ORDER BY
    v.month; 
    
    -- ==========treatment Cost Yearwise==============
SELECT
    v.Year as year,
    ROUND(SUM(t.TreatmentCost),2) AS TotalTreatmentCost
FROM visit v
JOIN treatment t
    ON v.VisitID = t.VisitID
GROUP BY
	v.year
ORDER BY
    v.year; 
-- ==========Month-wise patient visit count=================    
SELECT
v.Year,
v.Month,
COUNT(VisitID) AS PatientVisits
FROM visit as v
GROUP BY
    v.YEAR,
    v.MONTH
ORDER BY
    v.YEAR,
    v.MONTH;
-- =============Average treatment cost by diagnosis ===========
   SELECT
    v.Diagnosis,
    COUNT(t.TreatmentCost) AS `Treatment Count`,
    ROUND(AVG(t.TreatmentCost), 2) AS `Average Treatment Cost`
FROM visit AS v
JOIN treatment AS t
    ON v.VisitID = t.VisitID
GROUP BY v.Diagnosis
ORDER BY `Average Treatment Cost` DESC;

-- =============average experience by speciality =============
SELECT
    Specialty,
    ROUND(AVG(`Years Of Experience`), 1) AS `Average Experience`
FROM doctor
GROUP BY Specialty
ORDER BY `Average Experience` DESC;

-- ==========Total Scheduled Cases ============

SELECT
    COUNT(*) AS `Total Scheduled Cases`
FROM visit
WHERE `Visit Status`= 'Scheduled';
-- ============Test count by test name ===============
SELECT
    TestName AS `Test Name`,
    COUNT(*) AS `Test Count`
FROM labtest
GROUP BY TestName
ORDER BY `Test Count` DESC;

-- =============Performance Testing (Query Execution Time)=============
 
 SELECT * FROM Visit WHERE VisitDate BETWEEN '2023-01-01' AND '2023-12-31';

