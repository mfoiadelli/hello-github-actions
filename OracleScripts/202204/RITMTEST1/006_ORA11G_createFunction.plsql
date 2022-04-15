--Function Header
CREATE OR REPLACE FUNCTION circle_area (radius NUMBER) 
RETURN NUMBER IS
--Declare a constant and a variable
pi  	CONSTANT NUMBER(7,2) :=	3.141;
area 	NUMBER(7,2);
BEGIN
  --Area of Circle pi*r*r;
  area := pi * (radius * radius);
  RETURN area; 
END;
/
