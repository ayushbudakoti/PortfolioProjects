/*

Cleaning Data in SQL Queries

*/


Select *
From DATACLEANING.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format


Select saleDateConverted, CONVERT(Date,SaleDate)
From PortfolioProject.dbo.NashvilleHousing


Update NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

-- If it doesn't Update properly

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

Select *
From DATACLEANING.dbo.NashvilleHousing
--Where PropertyAddress is null
order by ParcelID



Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From DATACLEANING.dbo.NashvilleHousing a
JOIN DATACLEANING.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From DATACLEANING.dbo.NashvilleHousing a
JOIN DATACLEANING.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null




--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


Select PropertyAddress
From DATACLEANING.dbo.NashvilleHousing
--Where PropertyAddress is null
--order by ParcelID

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address

From DATACLEANING.dbo.NashvilleHousing


ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))




Select OwnerAddress
From DATACLEANING.dbo.NashvilleHousing



select
PARSENAME(Replace(OwnerAddress,',','.'),3)
,PARSENAME(Replace(OwnerAddress,',','.'),2)
,PARSENAME(Replace(OwnerAddress,',','.'),1)
from DATACLEANING.dbo.NashvilleHousing




ALTER TABLE NashvilleHousing
Add ownerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET ownersplitAddress = PARSENAME(Replace(OwnerAddress,',','.'),3)


ALTER TABLE NashvilleHousing
Add ownerSplitCity Nvarchar(255);

Update NashvilleHousing
SET ownerSplitCity =PARSENAME(Replace(OwnerAddress,',','.'),2)


ALTER TABLE NashvilleHousing
Add ownerSplitstate Nvarchar(255);

Update NashvilleHousing
SET ownerSplitstate =PARSENAME(Replace(OwnerAddress,',','.'),1)

------------------------------------------------------------------------------------------------------------------


--change 0 and 1 to yes and no in 'sold as vacant ' field

select Distinct(soldasvacant), COUNT(soldasvacant)
from DATACLEANING.dbo.NashvilleHousing
group by SoldAsVacant
order by 2


SELECT 
    soldasvacant,
    CASE 
        WHEN soldasvacant = 1 THEN 'Yes'
        WHEN soldasvacant = 0 THEN 'No'
        ELSE CAST(soldasvacant AS NVARCHAR(255))
    END AS soldasvacant_status
FROM 
    DATACLEANING.dbo.NashvilleHousing;

	ALTER TABLE NashvilleHousing 
ALTER COLUMN SoldAsVacant NVARCHAR(255);

UPDATE NashvilleHousing
SET SoldAsVacant = 
    CASE 
        WHEN soldasvacant = '1' THEN 'Yes'
        WHEN soldasvacant = '0' THEN 'No'
        ELSE soldasvacant



    END;


	----------------------------------------------------------------------------------
	--removing duplicates
	with RowNumCTE as (
	select*,
	      ROW_NUMBER() over (
		  partition by ParcelID,
		               PropertyAddress,
					   SalePrice,
					   SaleDate,
					   LegalReference
					   order by
					         UniqueID
							 ) Row_num
from DATACLEANING.dbo.NashvilleHousing
--order by ParcelID
)
SELECT*
FROM RowNumCTE
WHERE ROW_NUM > 1
ORDER BY PropertyAddress



-------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns
select *
from DATACLEANING.dbo.NashvilleHousing

ALTER TABLE  DATACLEANING.dbo.NashvilleHousing
Drop Column  PropertyAddress

ALTER TABLE  DATACLEANING.dbo.NashvilleHousing
Drop Column  SaleDate







































