-- The package contains types shared by the tests.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package test_types is

    generic (ORDER : integer);

    subtype A_TYPE is STD_LOGIC_VECTOR (2**ORDER - 1 downto 0);
    subtype S_TYPE is STD_LOGIC_VECTOR (   ORDER - 1 downto 0);
    
    type TEST_ENTRY is record
        a : A_TYPE;
        s : S_TYPE;
        y : STD_LOGIC;
    end record;
    type TEST_COLLECTION is array (integer range <>) of TEST_ENTRY;

end package test_types;

package body test_types is
end package body test_types;

