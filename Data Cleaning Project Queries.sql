-- We manually deleted all spaces of each column name
-- SQL can also delete all of the space from column name, but it's a little bit noisy.
-- -- ALTER TABLE data_cleaning.original 
-- -- RENAME COLUMN 'column Name' to 'columnName';


-- Then we found the data type of the SaleDate column is 'datetime', which is inconvienient for the later on analysis, so we change the date type into 'date'

Alter Table data_cleaning.original
Modify SaleDate Date;

Select * From data_cleaning.original;



-- Populate Property Address data
-- But actually if you import the csv file into MySQL Server, the null value will be automatically deleted from the import process

Select PropertyAddress From data_cleaning.NashvilleHousing
Where PropertyAddress Is Null;

Update data_cleaning.NashvilleHousing a
Join data_cleaning.NashvilleHousing b 
	On (a.ParcelID = b.ParcelID) And (a.UniqueID <> b.UniqueID)
SET a.PropertyAddress = IFNULL(a.PropertyAddress,b.PropertyAddress)
Where a.PropertyAddress Is Null;



-- Breaking out Address into Individual Columns (Address, City, State)

Select PropertyAddress
From data_cleaning.NashvilleHousing
-- Where PropertyAddress is null
-- order by ParcelID
;

SELECT
	SUBSTRING(PropertyAddress, 1, POSITION(',' in PropertyAddress) - 1 ) as Address1, 
    SUBSTRING(PropertyAddress, POSITION(',' IN PropertyAddress) + 1 , LENGTH(PropertyAddress)) as Address
From data_cleaning.NashvilleHousing;

ALTER TABLE data_cleaning.NashvilleHousing
ADD Address VARCHAR(255);
-- SELECT PropertySplitAddress FROM data_cleaning.NashvilleHousing;
SET SQL_SAFE_UPDATES = 0;
UPDATE data_cleaning.NashvilleHousing 
SET Address = SUBSTRING(PropertyAddress, 1, POSITION(',' in PropertyAddress) - 1 );
SET SQL_SAFE_UPDATES = 1;
-- SELECT Address from data_cleaning.NashvilleHousing;

ALTER TABLE data_cleaning.NashvilleHousing
Add PropertySplitCity Nvarchar(255);

SET SQL_SAFE_UPDATES = 0;
Update data_cleaning.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, POSITION(',' IN PropertyAddress) + 1 , LENGTH(PropertyAddress));
SET SQL_SAFE_UPDATES = 1;
-- SELECT PropertySplitCity from data_cleaning.NashvilleHousing;

Select *
From data_cleaning.NashvilleHousing;



-- Deal with the OwnerAddress column

Select OwnerAddress
From data_cleaning.NashvilleHousing;

SELECT 
    SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', -1) AS Owner_State,
    SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', -2), '.', 1) AS Owner_City,
    SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', -3), '.', 1) AS Owner_Address
FROM data_cleaning.NashvilleHousing;

ALTER TABLE data_cleaning.NashvilleHousing
Add Owner_State Nvarchar(255);

SET SQL_SAFE_UPDATES = 0;

Update data_cleaning.NashvilleHousing
SET Owner_State = SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', -1);

ALTER TABLE data_cleaning.NashvilleHousing
Add Owner_City Nvarchar(255);

Update data_cleaning.NashvilleHousing
SET Owner_City = SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', -2), '.', 1);

ALTER TABLE data_cleaning.NashvilleHousing
Add Owner_Address Nvarchar(255);

Update data_cleaning.NashvilleHousing
SET Owner_Address = SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', -3), '.', 1);
SET SQL_SAFE_UPDATES = 1;

Select *
From data_cleaning.NashvilleHousing



-- Change Y and N to Yes and No in "Sold as Vacant" field

Select Distinct SoldAsVacant, Count(SoldAsVacant)
From data_cleaning.NashvilleHousing
Group by SoldAsVacant
order by 2;

Select SoldAsVacant, 
	CASE 
		When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
From data_cleaning.NashvilleHousing;

SET SQL_SAFE_UPDATES = 0;
Update data_cleaning.NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes' 
						When SoldAsVacant = 'N' THEN 'No'
					ELSE SoldAsVacant
					END;
SET SQL_SAFE_UPDATES = 1;

SELECT SoldAsVacant FROM data_cleaning.NashvilleHousing GROUP BY SoldAsVacant;



-- Remove Duplicates

WITH RowNumCTE AS
(Select *, 
		ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS 'row_num' 
From data_cleaning.NashvilleHousing)
 
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress;

Select *
From data_cleaning.NashvilleHousing



-- Delete Unused Columns

Select *
From data_cleaning.NashvilleHousing;

SET SQL_SAFE_UPDATES = 0;
ALTER TABLE data_cleaning.NashvilleHousing
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress, 
DROP COLUMN SaleDate;
SET SQL_SAFE_UPDATES = 1;