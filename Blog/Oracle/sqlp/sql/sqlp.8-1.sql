SELECT 
       SUM(C) AS 전체사원수,
       COUNT(*) AS 부서개수,
       AVG(C) AS 부서별평균사원수,
       MAX(C) AS 부서별최대사원수,
       MIN(C) AS 부서별최소사원수,
       MIN(MIN_D) AS 최소사원수부서,
       MIN(MAX_D) AS 최대사원수부서
  FROM (
SELECT DEPTNO, COUNT(*) C,
       FIRST_VALUE(DEPTNO) OVER (ORDER BY COUNT(*)) AS MIN_D,
       FIRST_VALUE(DEPTNO) OVER (ORDER BY COUNT(*) DESC) AS MAX_D
 FROM EMP GROUP BY DEPTNO ORDER BY COUNT(*)
)