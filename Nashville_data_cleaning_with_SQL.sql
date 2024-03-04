/*
=========================================================================================
= Cleaning Dataset Using SQL Queries                                                    =
=========================================================================================
*/

select *
from Portfolio..NashvilleHousingDataCleaning

/*
=========================================================================================
= Standarize Date Format                                                                =
=========================================================================================
*/

select SaleDate
from Portfolio..NashvilleHousingDataCleaning

select SaleDate, CONVERT(date, SaleDate)
from Portfolio..NashvilleHousingDataCleaning

update Portfolio..NashvilleHousingDataCleaning
set SaleDate = CONVERT(date, SaleDate)

alter table Portfolio..NashvilleHousingDataCleaning
add SaleDateConverted date;

update Portfolio..NashvilleHousingDataCleaning
set SaleDateConverted = CONVERT(date, SaleDate)

/*
=========================================================================================
= Populate Property Address Data                                                        =
=========================================================================================
*/

select *
from Portfolio..NashvilleHousingDataCleaning
where PropertyAddress is Null

select *
from Portfolio..NashvilleHousingDataCleaning
order by ParcelID
 -- 1) 

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
from Portfolio..NashvilleHousingDataCleaning a
join Portfolio..NashvilleHousingDataCleaning b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null

-- 2)

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
from Portfolio..NashvilleHousingDataCleaning a
join Portfolio..NashvilleHousingDataCleaning b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null

update a
set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from Portfolio..NashvilleHousingDataCleaning a
join Portfolio..NashvilleHousingDataCleaning b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null

-- Verification:

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
from Portfolio..NashvilleHousingDataCleaning a
join Portfolio..NashvilleHousingDataCleaning b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null

update a
set PropertyAddress = ISNULL(a.PropertyAddress, 'No Address')
from Portfolio..NashvilleHousingDataCleaning a
join Portfolio..NashvilleHousingDataCleaning b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null

/*
=========================================================================================
= Breaking out address in individual columns (Address, City, State)                     =
=========================================================================================
*/

select PropertyAddress
from Portfolio..NashvilleHousingDataCleaning

 -- we put -1 to remove the ','
 
select
substring (PropertyAddress, 1, charindex(',', PropertyAddress) - 1) as Address,
	substring (PropertyAddress, charindex(',', PropertyAddress) + 1, len(PropertyAddress)) as City
from Portfolio..NashvilleHousingDataCleaning

alter table Portfolio..NashvilleHousingDataCleaning
add PropertySplitAddress nvarchar(255);

update Portfolio..NashvilleHousingDataCleaning
set PropertySplitAddress = substring (PropertyAddress, 1, charindex(',', PropertyAddress) - 1)

alter table Portfolio..NashvilleHousingDataCleaning
add PropertySplitCity nvarchar(255);

update Portfolio..NashvilleHousingDataCleaning
set PropertySplitCity = substring (PropertyAddress, charindex(',', PropertyAddress) + 1, len(PropertyAddress))


-- splitting OwnerAddress Column

select OwnerAddress
from Portfolio..NashvilleHousingDataCleaning

select
PARSENAME(replace(OwnerAddress, ',', '.'), 3) as Address,
	PARSENAME(replace(OwnerAddress, ',', '.'), 2) as City,
	PARSENAME(replace(OwnerAddress, ',', '.'), 1) as State
from Portfolio..NashvilleHousingDataCleaning

alter table Portfolio..NashvilleHousingDataCleaning
add OwnerSplitAddress nvarchar(255);

update Portfolio..NashvilleHousingDataCleaning
set OwnerSplitAddress = PARSENAME(replace(OwnerAddress , ',', '.'), 3)

alter table Portfolio..NashvilleHousingDataCleaning
add OwnerSplitCity nvarchar(255);

update Portfolio..NashvilleHousingDataCleaning
set OwnerSplitCity = PARSENAME(replace(OwnerAddress, ',', '.'), 2)

alter table Portfolio..NashvilleHousingDataCleaning
add OwnerSplitState nvarchar(255);

update Portfolio..NashvilleHousingDataCleaning
set OwnerSplitState = PARSENAME(replace(OwnerAddress, ',', '.'), 1)

/*
=========================================================================================
= Changing 'Y' and 'N' or '0' and '1' into Yes or No in "Sold as Vacant" field          =
=========================================================================================
*/

select distinct (SoldAsVacant)
from Portfolio..NashvilleHousingDataCleaning

select distinct (SoldAsVacant), COUNT(SoldAsVacant)
from Portfolio..NashvilleHousingDataCleaning
group by SoldAsVacant
order by SoldAsVacant

select SoldAsVacant,
CASE
	when SoldAsVacant = '0' then 'No'
	when SoldAsVacant = '1' then 'Yes'
	else SoldAsVacant
	end
from Portfolio..NashvilleHousingDataCleaning

update NashvilleHousingDataCleaning
set SoldAsVacant = CASE when SoldAsVacant = '0' then 'No'
	when SoldAsVacant = '1' then 'Yes'
	else SoldAsVacant
	end
from Portfolio..NashvilleHousingDataCleaning

select distinct SoldAsVacant
from Portfolio..NashvilleHousingDataCleaning

/*
=========================================================================================
= Remove Duplicates                                                                     =
=========================================================================================
*/

--step 1

WITH RowNumCTE AS (
	select *,
		ROW_NUMBER()Over(
		partition by ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate, 
		LegalReference
		order by
			UniqueID
			) row_num
	from Portfolio..NashvilleHousingDataCleaning
)

select *
from RowNumCTE

--step 2

WITH RowNumCTE AS (
	select *,
		ROW_NUMBER()Over(
		partition by ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate, 
		LegalReference
		order by
			UniqueID
			) row_num
	from Portfolio..NashvilleHousingDataCleaning
)

select *
from RowNumCTE
where row_num > 1
order by PropertyAddress

--step 3

WITH RowNumCTE AS (
	select *,
		ROW_NUMBER()Over(
		partition by ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate, 
		LegalReference
		order by
			UniqueID
			) row_num
	from Portfolio..NashvilleHousingDataCleaning
)

delete
from RowNumCTE
where row_num > 1

--step 4

WITH RowNumCTE AS (
	select *,
		ROW_NUMBER()Over(
		partition by ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate, 
		LegalReference
		order by
			UniqueID
			) row_num
	from Portfolio..NashvilleHousingDataCleaning
)

select *
from RowNumCTE
where row_num > 1
order by PropertyAddress

/*
=========================================================================================
= Remove unused columns                                                                 =
=========================================================================================
*/

select *
from Portfolio..NashvilleHousingDataCleaning

alter table Portfolio..NashvilleHousingDataCleaning
drop column OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

