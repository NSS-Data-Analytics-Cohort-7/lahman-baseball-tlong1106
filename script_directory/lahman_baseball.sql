/*
   1. What range of years for baseball games played does the provided database cover?
*/

   SELECT MIN(year),
     MAX(year),
     MAX(year) - MIN(year) AS year_range
   FROM homegames;

/*
   2. Find the name and height of the shortest player in the database. How many games did he play in? What
      is the name of the team for which he played?
*/

   SELECT CONCAT(p.namefirst, ' ', p.namelast) as name,
     p.height,
     a.g_all AS games_played,
     t.name AS team_name
   FROM people AS p
   INNER JOIN appearances AS a
   ON p.playerid = a.playerid
   INNER JOIN teams AS t
   ON a.teamid = t.teamid
   WHERE p.height = (SELECT MIN(height)
                     FROM people)
   GROUP BY p.namelast,
     p.namefirst,
     p.height,
     a.g_all,
     t.name;

/*
    3. Find all players in the database who played at Vanderbilt University. Create a list showing each
       player’s first and lastnames as well as the total salary they earned in the major leagues. Sort
       this list in descending order by the total salaryearned. Which Vanderbilt player earned the most
       money in the majors?
*/

    -- Original query, keep as it is: David Price / $81,851,296.00
    SELECT CONCAT(vandy.namefirst, ' ', vandy.namelast) AS name,
      CAST(CAST(SUM(s.salary) AS numeric) AS money) AS player_pay
    FROM (SELECT p.playerid,
            p.namefirst,
            p.namelast
          FROM people AS p
          LEFT JOIN collegeplaying AS cp
          USING (playerid)
          JOIN schools AS s
          USING (schoolid)
          WHERE s.schoolname LIKE '%Vanderbilt%'
          GROUP BY p.playerid) AS vandy
    JOIN salaries AS s
    ON vandy.playerid = s.playerid
    WHERE s.salary IS NOT null
    GROUP BY vandy.namefirst,
      vandy.namelast
    ORDER BY player_pay DESC;

    -- Sanity check
    SELECT 
      namefirst,
      namelast,
      money(CAST(SUM(salary) AS numeric))
    FROM people
    JOIN salaries
    USING (playerid)
    WHERE namelast = 'Price' AND namefirst = 'David'
    GROUP BY namelast, namefirst;
    
    -- Sarah's code with different answer: David Price / vandy / $245,553,888.00
    SELECT p.namefirst AS first, p.namelast AS last, c.schoolid, CAST(CAST(SUM(s.salary) AS NUMERIC) AS MONEY)
    FROM collegeplaying AS c
    JOIN people AS p
    USING (playerid)
    JOIN salaries AS s
    USING (playerid)
    WHERE schoolid = 'vandy'
    GROUP BY p.namefirst, p.namelast, c.schoolid
    ORDER BY SUM(s.salary) DESC;

/*
   4. Using the fielding table, group players into three groups based on their position: label players
   with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those
   with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three
   groups in 2016.
*/

    SELECT SUM(po) AS putouts,
      CASE WHEN pos IN ('OF') THEN 'outfield'
           WHEN pos IN ('SS','1B','2B','3B') THEN 'infield'
           WHEN pos IN ('P','C') THEN 'battery' END AS player_position
    FROM fielding
    WHERE yearid = '2016'
    GROUP BY player_position;

/*
    5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report
    to 2 decimal places. Do the same for home runs per game. Do you see any trends?
*/
    
    -- Average strikeouts per game per decade
    SELECT 
      ((yearid/10)*10) AS decade,
      ROUND(AVG((CAST(so AS numeric)/CAST(g AS numeric))),2)*2 AS avg_so_per_g
    FROM teams
    WHERE ((yearid/10)*10) >= 1920
    GROUP BY decade
    ORDER BY decade;

    -- Average homeruns per game per decade
    SELECT 
      ((yearid/10)*10) AS decade,
      --COUNT(g) AS num_games,
      --SUM(so) AS num_so,
      ROUND(AVG((CAST(hr AS numeric)/CAST(g AS numeric))),2)*2 AS avg_hr_per_g
    FROM teams
    WHERE ((yearid/10)*10) >= 1920
    GROUP BY decade
    ORDER BY decade;
    
/*
    6. Find the player who had the most success stealing bases in 2016, where success is measured as the
    percentage of stolen base attempts which are successful. (A stolen base attempt results either in a
    stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.
*/

    SELECT
      /*p.playerid,*/
      CONCAT(p.namefirst, ' ', p.namelast) AS name,
      /*SUM*/(b.sb) AS stolen_base,
      /*SUM*/(b.cs) AS caught_steal,
      /*SUM*/(b.sb + b.cs) AS total_attempt,
      ROUND((CAST(b.sb AS numeric)/(CAST(b.sb AS numeric)+CAST(b.cs AS numeric))*100),2) AS success_percent
    FROM batting AS b
    JOIN people AS p
    ON b.playerid = p.playerid
    WHERE yearid = 2016 AND b.sb IS NOT NULL
    GROUP BY p.playerid, p.namelast, p.namefirst, b.sb, b.cs
    HAVING /*MAX*/(b.sb+b.cs) > 20
    ORDER BY success_percent DESC;

/*
    7. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest
    number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins
    for a world series champion – determine why this is the case. Then redo your query, excluding the problem year.
*/

    -- Most wins for team that did not win World Series
    SELECT
      yearid,
      teamid,
      /*MAX*/(w)
    FROM teams
    WHERE yearid >= 1970 AND wswin = 'N'
    GROUP BY yearid, teamid, w
    ORDER BY w DESC
    LIMIT 1;
    
    -- Smallest number of wins for a team that did win World Series
    SELECT
      yearid,
      teamid,
      /*MIN*/(w)
    FROM teams
    WHERE yearid >= 1970 AND wswin = 'Y' AND yearid != 1981
    GROUP BY yearid, teamid, w
    ORDER BY w
    LIMIT 1;
    
/*    
How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
*/

    -- Final Query
    WITH max_wins AS (SELECT 
                        yearid,
                        MAX(w)
                      FROM teams
                      WHERE yearid BETWEEN 1970 AND 2016 AND yearid <> 1994
                      GROUP BY yearid
                      ORDER BY yearid DESC)
    SELECT
      name,
      MAX(w)
    FROM teams
    JOIN max_wins
    USING (yearid)
    WHERE yearid BETWEEN 1970 AND 2016 AND wswin = 'Y'
    GROUP BY name
    ORDER BY MAX(w) DESC;
    
    -- Teams with most wins per year
    WITH max_wins AS (SELECT 
                        DISTINCT yearid,
                        MAX(w) AS m_w
                      FROM teams
                      WHERE yearid BETWEEN 1970 AND 2016 AND yearid <> 1994
                      GROUP BY yearid
                      ORDER BY yearid DESC)
    
    -- Teams that won World Series
    SELECT yearid, name
    FROM teams
    WHERE wswin = 'Y' AND yearid BETWEEN 1970 AND 2016
    ORDER BY yearid DESC;

/*
    8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per
    game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where
    there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average
    attendance.
*/

-- CTE practice to JOIN these tables

    -- Top 5 average attendance
    SELECT
      park_name,
      team,
      (attendance/games) AS avg_attendance
    FROM parks AS p
    JOIN homegames AS h
    USING (park)
    WHERE games > 10 AND year = 2016
    GROUP BY
      park_name,
      team,
      avg_attendance
    ORDER BY avg_attendance DESC
    LIMIT 5;

    -- Bottom 5 average attendance
    SELECT
      park_name,
      team,
      (attendance/games) AS avg_attendance
    FROM parks AS p
    JOIN homegames AS h
    USING (park)
    WHERE games > 10 AND year = 2016
    GROUP BY
      park_name,
      team,
      avg_attendance
    ORDER BY avg_attendance
    LIMIT 5;

/*
    9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)?
    Give their full name and the teams that they were managing when they won the award.
*/

    WITH team_managers AS (SELECT
                            ma.yearid,
                            playerid,
                            name,
                            franchname
                           FROM managers AS ma
                           JOIN teams AS t
                           USING (teamid, yearid)
                           JOIN teamsfranchises AS tf
                           USING (franchid)
                           GROUP BY name, playerid, ma.yearid, franchname)
    SELECT
      p.namefirst,
      p.namelast,
      a.lgid,
      a.yearid,
      name
    FROM awardsmanagers AS a
    JOIN people AS p
    USING (playerid)
    JOIN team_managers AS tm
    USING (playerid, yearid)
    WHERE awardid = 'TSN Manager of the Year' AND lgid IN ('AL', 'NL')
    GROUP BY
      p.namefirst,
      p.namelast,
      a.lgid,
      a.yearid,
      name
    ORDER BY yearid DESC;

/*
    10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the
    league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the
    number of home runs they hit in 2016.
*/

    SELECT