function Export-GtHtmlReport {
    <#
    .SYNOPSIS
    Generate a Bootstrap HTML report from any array of objects. 

    .DESCRIPTION
    [AI-GENERATED] This hot mess of PowerShell and JavaScript was generated using Claude Haiku 4.5.
    Generates a self-contained HTML report from an array of objects using Bootstrap 5 for styling and javaScript for interactivity.
    
    Auto-detects object structure and renders one of three view modes:
    1. Table View (flat objects)
    When all properties are simple types (strings, numbers, dates, booleans). Rendered as a searchable, sortable table with per-column filters.
    
    2. Card View - Single Section (one complex property)
    When the object has one nested/complex property. Rendered as cards with a full-width section for the complex property.
    Search filters mini-table rows within visible cards.
    
    3. Card View - Grid Layout (multiple complex properties)
    When the object has two or more nested/complex properties. Rendered as cards with a responsive multi-column grid layout.
    Search shows entire card content without filtering rows.

    .PARAMETER InputObject
    The objects to render in the report. Accepts pipeline input.

    .PARAMETER TitleProperty
    Property name to use as card titles. Defaults to 'displayName'.

    .PARAMETER Path
    Output file path. Defaults to '.\Report.html'.

    .PARAMETER ReportTitle
    Title displayed at the top of the report.

    .PARAMETER NoOpen
    Suppress automatic opening of the report in default browser.

    .PARAMETER PageSize
    Number of items per page. Defaults to 100.

    .EXAMPLE
    $users | Export-GtHtmlReport -Path ".\Users.html" -ReportTitle "User Report"
    
    Generates a table view report for flat user objects.

    .EXAMPLE
    Get-GtConditionalAccessPolicies | Export-GtHtmlReport -TitleProperty displayName
    
    Generates a card view report for complex policy objects.

    .EXAMPLE
    $roles | Export-GtHtmlReport -PageSize 50 -NoOpen
    
    Generates a report with 50 items per page without opening it.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Export-GtHtmlReport.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object[]]$InputObject,
        
        [Parameter()]
        [string]$TitleProperty = "displayName",
        
        [Parameter()]
        [string]$Path = ".\report.html",
        
        [Parameter()]
        [string]$ReportTitle = "Object Report",
        
        [Parameter()]
        [switch]$NoOpen,
        
        [Parameter()]
        [ValidateRange(10, 1000)]
        [int]$PageSize = 100
    )
    
    begin { $allObjects = @() }
    process { $allObjects += $InputObject }
    end {
        if ($allObjects.Count -eq 0) { Write-Warning "No objects to export."; return }
        if ($allObjects.Count -ge 1000) { Write-Warning "Export-GtHtmlReport: Rendering $($allObjects.Count) objects may take a while." }

        #region Constants - used for null display
        $Script:NullPlaceholder = '<span class="text-muted fst-italic">-</span>'
        #endregion

        #region Helper Functions
        
        # Pre-compile regex patterns for reuse (CLM-safe - these are just strings used with -match/-replace)
        $rxSimpleType = 'String|Int32|Int64|Double|Boolean|DateTime|Guid'
        $rxCollection = '\[\]|Collection|ArrayList|List'
        $rxOData = '@odata'
        
        function Encode-Html {
            <# HTML encode text (CLM-safe, no method calls) #>
            param([string]$Text)
            if (-not $Text) { return $Text }
            $Text -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;' -replace "'",'&#39;'
        }

        function Test-SimpleType {
            <# Check if value is a simple/primitive type #>
            param($Value)
            $null -ne $Value -and $Value.PSTypeNames[0] -match $rxSimpleType
        }

        function Test-IsCollection {
            <# Check if value is a collection/array #>
            param($Value)
            if ($null -eq $Value) { return $false }
            $typeName = $Value.PSTypeNames[0]
            ($typeName -match $rxCollection) -or 
            ($null -ne $Value.Count -and $Value.Count -gt 0 -and $typeName -notmatch 'String')
        }

        function Test-FlatObject {
            <# Check if object has only simple properties (for table view detection) #>
            param($Obj)
            foreach ($prop in $Obj.PSObject.Properties) {
                $val = $prop.Value
                if ($null -eq $val) { continue }
                # Inline type check to avoid function call overhead in hot path
                $typeName = $val.PSTypeNames[0]
                if ($typeName -match $rxSimpleType) { continue }
                if (($typeName -match $rxCollection) -or ($null -ne $val.Count -and $val.Count -gt 0 -and $typeName -notmatch 'String')) {
                    if ($val.Count -eq 0) { continue }
                    $firstItem = $val[0]
                    if ($null -ne $firstItem -and $firstItem.PSTypeNames[0] -match $rxSimpleType) { continue }
                    return $false
                }
                return $false
            }
            return $true
        }

        function Get-DisplayValue {
            <# Get best display value from an object #>
            param($Item)
            if ($null -eq $Item) { return "-" }
            if (Test-SimpleType $Item) { return "$Item" }
            foreach ($prop in 'displayName', 'name', 'id') {
                if ($Item.$prop) { return $Item.$prop }
            }
            if ($Item.Count) { return "($($Item.Count) items)" }
            return "$Item"
        }

        function Format-TableValue {
            <# Format value for table cell display #>
            param($Value)
            if ($null -eq $Value) { return "-" }
            if ($Value -is [DateTime]) { return Encode-Html ("{0:dd.MM.yyyy HH:mm:ss}" -f $Value) }
            if (Test-SimpleType $Value) { return Encode-Html "$Value" }
            if (Test-IsCollection $Value) {
                if ($Value.Count -eq 0) { return "-" }
                return Encode-Html (($Value | ForEach-Object { Get-DisplayValue $_ }) -join ", ")
            }
            return Encode-Html (Get-DisplayValue $Value)
        }

        function New-Badge {
            <# Create a badge HTML element #>
            param([string]$Text, [string]$Class = 'bg-info text-dark')
            "<span class='badge $Class me-1'>$(Encode-Html $Text)</span>"
        }

        function Format-CollectionAsTable {
            <# Format collection of complex objects as mini-table #>
            param($Collection)
            
            # Get columns from first item's property names (not values) to ensure all columns are included
            $firstItem = $Collection[0]
            $candidateColumns = @(foreach ($p in $firstItem.PSObject.Properties) {
                $pName = $p.Name
                if ($pName -notmatch $rxOData) { $pName }
            })
            
            # Filter to only simple-type columns by checking if ANY item has a simple-type value for that property
            $columns = @(foreach ($propName in $candidateColumns) {
                $sampleValue = $null
                foreach ($item in $Collection) {
                    $v = $item.$propName
                    if ($null -ne $v) { $sampleValue = $v; break }
                }
                if ($null -eq $sampleValue -or ($sampleValue.PSTypeNames[0] -match $rxSimpleType)) {
                    $propName
                }
            })
            
            if ($columns.Count -eq 0) { 
                return "<span class='badge bg-secondary'>$($Collection.Count) items</span>" 
            }
            
            # Build header - use foreach for speed
            $headerParts = foreach ($col in $columns) { "<th class='small'>$(Encode-Html $col)</th>" }
            $headerHtml = $headerParts -join ''
            
            # Build rows - use foreach for speed
            $rowParts = foreach ($item in $Collection) {
                $cellParts = foreach ($col in $columns) {
                    $cellVal = $item.$col
                    if ($null -eq $cellVal) { "<td class='small'>-</td>" }
                    else { 
                        $displayVal = if ($cellVal -is [DateTime]) { "{0:dd.MM.yyyy HH:mm:ss}" -f $cellVal } else { "$cellVal" }
                        "<td class='small'>$(Encode-Html $displayVal)</td>" 
                    }
                }
                "<tr>$($cellParts -join '')</tr>"
            }
            $rowsHtml = $rowParts -join ''
            
            @"
<div class="table-responsive card-table-container" style="max-height:300px;overflow-y:auto;">
<div class="table-filter-info small text-muted mb-1" style="display:none;"></div>
<table class="table table-sm table-bordered mb-0 card-mini-table">
<thead class="table-secondary"><tr>$headerHtml</tr></thead>
<tbody>$rowsHtml</tbody>
</table>
</div>
"@
        }

        function Format-ObjectAsSection {
            <# Format nested object as visual section (recursive) #>
            param($Obj, [int]$Depth = 0)
            
            if ($Depth -gt 2) { 
                $json = $Obj | ConvertTo-Json -Compress -Depth 3
                return "<code class='small text-break'>$(Encode-Html $json)</code>"
            }
            
            $parts = foreach ($prop in $Obj.PSObject.Properties) {
                $propName = $prop.Name
                $val = $prop.Value
                
                if ($propName -match $rxOData -or $null -eq $val) { continue }
                
                # Inline type checks to reduce function call overhead
                $typeName = $val.PSTypeNames[0]
                $isSimple = $typeName -match $rxSimpleType
                
                if ($isSimple) {
                    $displayVal = if ($val -is [DateTime]) { "{0:dd.MM.yyyy HH:mm:ss}" -f $val } else { "$val" }
                    "<div class='mb-1'><strong class='text-muted'>${propName}:</strong> $(New-Badge $displayVal)</div>"
                }
                elseif (($typeName -match $rxCollection) -or ($null -ne $val.Count -and $val.Count -gt 0 -and $typeName -notmatch 'String')) {
                    if ($val.Count -eq 0) { continue }
                    $firstItem = $val[0]
                    
                    if ($null -ne $firstItem -and $firstItem.PSTypeNames[0] -match $rxSimpleType) {
                        $badges = foreach ($v in $val) { 
                            $displayVal = if ($v -is [DateTime]) { "{0:dd.MM.yyyy HH:mm:ss}" -f $v } else { "$v" }
                            New-Badge $displayVal
                        }
                        "<div class='mb-1'><strong class='text-muted'>${propName}:</strong> $($badges -join '')</div>"
                    }
                    else {
                        $tableHtml = Format-CollectionAsTable $val
                        "<div class='mb-2'><strong class='text-muted'>${propName}:</strong> <span class='badge bg-secondary'>$($val.Count) items</span>$tableHtml</div>"
                    }
                }
                else {
                    $nestedHtml = Format-ObjectAsSection $val ($Depth + 1)
                    "<div class='mb-2 ps-2 border-start border-2'><strong class='text-primary'>$propName</strong><div class='ps-2'>$nestedHtml</div></div>"
                }
            }
            
            if (-not $parts) { return $Script:NullPlaceholder }
            $parts -join ''
        }

        function Format-BadgeValue {
            <# Format value as badges for card display #>
            param($Value)
            if ($null -eq $Value) { return $Script:NullPlaceholder }
            
            # Check datetime first for proper formatting
            if ($Value -is [DateTime]) { return New-Badge ("{0:dd.MM.yyyy HH:mm:ss}" -f $Value) }
            
            # Inline type checks
            $typeName = $Value.PSTypeNames[0]
            if ($typeName -match $rxSimpleType) { return New-Badge "$Value" }
            
            if (($typeName -match $rxCollection) -or ($null -ne $Value.Count -and $Value.Count -gt 0 -and $typeName -notmatch 'String')) {
                if ($Value.Count -eq 0) { return $Script:NullPlaceholder }
                $firstItem = $Value[0]
                if ($null -ne $firstItem -and $firstItem.PSTypeNames[0] -match $rxSimpleType) {
                    $badges = foreach ($v in $Value) { New-Badge "$v" }
                    return ($badges -join '')
                }
                return Format-CollectionAsTable $Value
            }
            return Format-ObjectAsSection $Value 1
        }

        #endregion

        #region JavaScript Templates
        
        $sharedPaginationJs = @'
function renderPagination(totalPages) {
    var pag = document.getElementById('pagination');
    pag.innerHTML = '';
    
    function addPageItem(text, page, disabled, active) {
        var li = document.createElement('li');
        li.className = 'page-item' + (disabled ? ' disabled' : '') + (active ? ' active' : '');
        li.innerHTML = '<a class="page-link" href="#" onclick="goToPage(' + page + '); return false;">' + text + '</a>';
        pag.appendChild(li);
    }
    
    addPageItem('\u00AB', currentPage - 1, currentPage === 1, false);
    
    var startPage = Math.max(1, currentPage - 2);
    var endPage = Math.min(totalPages, startPage + 4);
    if (endPage - startPage < 4) startPage = Math.max(1, endPage - 4);
    
    for (var i = startPage; i <= endPage; i++) {
        addPageItem(i, i, false, i === currentPage);
    }
    
    addPageItem('\u00BB', currentPage + 1, currentPage === totalPages, false);
}

function updatePageInfo(filteredCount, totalCount, start, end) {
    var text = 'Showing ' + (filteredCount > 0 ? start + 1 : 0) + '-' + Math.min(end, filteredCount) + ' of ' + filteredCount;
    if (filteredCount !== totalCount) text += ' (filtered from ' + totalCount + ')';
    document.getElementById('pageInfo').textContent = text;
}
'@

        $tableViewJs = @"
var pageSize = $PageSize;
var currentPage = 1;
var allRows = [];
var filteredRows = [];
var sortCol = -1;
var sortAsc = true;

document.addEventListener('DOMContentLoaded', function() {
    allRows = Array.from(document.querySelectorAll('#dataTable tbody tr'));
    filteredRows = allRows.slice();
    renderPage();
});

function applyFilters() {
    var globalFilter = document.getElementById('searchBox').value.toLowerCase();
    var colFilters = Array.from(document.querySelectorAll('.col-filter')).map(function(input) {
        return { col: parseInt(input.dataset.col), value: input.value.toLowerCase() };
    });
    
    filteredRows = allRows.filter(function(row) {
        if (globalFilter && !row.textContent.toLowerCase().includes(globalFilter)) return false;
        var cells = row.querySelectorAll('td');
        return colFilters.every(function(f) {
            return !f.value || (cells[f.col] && cells[f.col].textContent.toLowerCase().includes(f.value));
        });
    });
    currentPage = 1;
    renderPage();
}

function clearFilters() {
    document.getElementById('searchBox').value = '';
    document.querySelectorAll('.col-filter').forEach(function(input) { input.value = ''; });
    filteredRows = allRows.slice();
    currentPage = 1;
    renderPage();
}

function sortTable(colIndex) {
    sortAsc = (sortCol === colIndex) ? !sortAsc : true;
    sortCol = colIndex;
    
    allRows.sort(function(a, b) {
        var aVal = a.querySelectorAll('td')[colIndex]?.textContent || '';
        var bVal = b.querySelectorAll('td')[colIndex]?.textContent || '';
        
        // Try numeric parsing first (handles negative numbers, integers, decimals)
        var numPattern = /^-?[\d.,\s%]+`$/;
        if (numPattern.test(aVal) && numPattern.test(bVal)) {
            var aNum = parseFloat(aVal.replace(/[^0-9.\-]/g, ''));
            var bNum = parseFloat(bVal.replace(/[^0-9.\-]/g, ''));
            if (!isNaN(aNum) && !isNaN(bNum)) {
                return sortAsc ? aNum - bNum : bNum - aNum;
            }
        }
        
        // Try date parsing (requires "DD.MM.YYYY" format with separators)
        var datePattern = /^\d{2}\.\d{2}\.\d{4}/;
        if (datePattern.test(aVal) && datePattern.test(bVal)) {
            var aDate = Date.parse(aVal.replace(/(\d{2})\.(\d{2})\.(\d{4})/, '`$3-`$2-`$1'));
            var bDate = Date.parse(bVal.replace(/(\d{2})\.(\d{2})\.(\d{4})/, '`$3-`$2-`$1'));
            if (!isNaN(aDate) && !isNaN(bDate)) {
                return sortAsc ? aDate - bDate : bDate - aDate;
            }
        }
        
        // Text comparison fallback
        var cmp = aVal.localeCompare(bVal, undefined, {numeric: true, sensitivity: 'base'});
        return sortAsc ? cmp : -cmp;
    });
    
    var tbody = document.querySelector('#dataTable tbody');
    allRows.forEach(function(row) { tbody.appendChild(row); });
    applyFilters();
    
    document.querySelectorAll('.sort-indicator').forEach(function(span) {
        span.textContent = parseInt(span.dataset.col) === sortCol ? (sortAsc ? ' \u25B2' : ' \u25BC') : '';
    });
}

function renderPage() {
    var totalPages = Math.ceil(filteredRows.length / pageSize) || 1;
    if (currentPage > totalPages) currentPage = totalPages;
    
    allRows.forEach(function(row) { row.style.display = 'none'; });
    var start = (currentPage - 1) * pageSize;
    var end = start + pageSize;
    filteredRows.slice(start, end).forEach(function(row) { row.style.display = ''; });
    
    updatePageInfo(filteredRows.length, allRows.length, start, end);
    renderPagination(totalPages);
}

function goToPage(page) {
    var totalPages = Math.ceil(filteredRows.length / pageSize) || 1;
    if (page >= 1 && page <= totalPages) {
        currentPage = page;
        renderPage();
    }
}

$sharedPaginationJs
"@

        $cardViewJs = @"
var pageSize = $PageSize;
var currentPage = 1;
var allCards = [];
var filteredCards = [];
var activeFilters = {};

document.addEventListener('DOMContentLoaded', function() {
    allCards = Array.from(document.querySelectorAll('#items .card'));
    filteredCards = allCards.slice();
    renderPage();
});

function applyAllFilters() {
    var searchFilter = document.getElementById('searchBox').value.toLowerCase();
    
    // Get all active dropdown filters - use getAttribute for consistent case handling
    activeFilters = {};
    document.querySelectorAll('.prop-filter').forEach(function(select) {
        if (select.value) {
            // HTML lowercases data-prop attribute value, so get it directly
            var propName = select.getAttribute('data-prop').toLowerCase();
            activeFilters[propName] = select.value;
        }
    });
    
    filteredCards = allCards.filter(function(card) {
        // Check text search
        if (searchFilter && !card.textContent.toLowerCase().includes(searchFilter)) return false;
        
        // Check dropdown filters via data attributes - use getAttribute for case-insensitive matching
        for (var prop in activeFilters) {
            var cardValue = card.getAttribute('data-' + prop);
            if (cardValue !== activeFilters[prop]) return false;
        }
        return true;
    });
    
    currentPage = 1;
    renderPage();
    applyMiniTableFilters(searchFilter);
}

function filterCards() {
    applyAllFilters();
}

function clearFilters() {
    document.getElementById('searchBox').value = '';
    document.querySelectorAll('.prop-filter').forEach(function(select) { select.value = ''; });
    activeFilters = {};
    filteredCards = allCards.slice();
    currentPage = 1;
    renderPage();
}

function applyMiniTableFilters(filter) {
    allCards.forEach(function(card) {
        var isVisible = card.style.display !== 'none';
        var isGridLayout = card.querySelector('.row.row-cols-1') !== null;
        
        card.querySelectorAll('.card-table-container').forEach(function(container) {
            var table = container.querySelector('.card-mini-table');
            var info = container.querySelector('.table-filter-info');
            if (!table) return;
            
            var rows = Array.from(table.querySelectorAll('tbody tr'));
            var totalRows = rows.length;
            
            // Grid layout or hidden cards: show all rows
            if (isGridLayout || !isVisible || !filter) {
                rows.forEach(function(row) { row.style.display = ''; });
                if (info) info.style.display = 'none';
                return;
            }
            
            // Single-section cards: filter rows
            var visibleRows = 0;
            rows.forEach(function(row) {
                var matches = row.textContent.toLowerCase().includes(filter);
                row.style.display = matches ? '' : 'none';
                if (matches) visibleRows++;
            });
            
            if (info) {
                info.style.display = visibleRows < totalRows ? 'block' : 'none';
                info.textContent = 'Showing ' + visibleRows + ' of ' + totalRows + ' items';
            }
        });
    });
}

function renderPage() {
    var totalPages = Math.ceil(filteredCards.length / pageSize) || 1;
    if (currentPage > totalPages) currentPage = totalPages;
    
    allCards.forEach(function(card) { card.style.display = 'none'; });
    var start = (currentPage - 1) * pageSize;
    var end = start + pageSize;
    filteredCards.slice(start, end).forEach(function(card) { card.style.display = ''; });
    
    updatePageInfo(filteredCards.length, allCards.length, start, end);
    renderPagination(totalPages);
}

function goToPage(page) {
    var totalPages = Math.ceil(filteredCards.length / pageSize) || 1;
    if (page >= 1 && page <= totalPages) {
        currentPage = page;
        renderPage();
        applyMiniTableFilters(document.getElementById('searchBox').value.toLowerCase());
    }
}

$sharedPaginationJs
"@

        #endregion

        #region Build Content
        
        $useTable = Test-FlatObject $allObjects[0]
        $escapedTitle = Encode-Html $ReportTitle

        if ($useTable) {
            # Table View - use foreach for speed
            $columns = @($allObjects[0].PSObject.Properties.Name)
            $colCount = $columns.Count
            
            # Build header with foreach
            $headerParts = for ($i = 0; $i -lt $colCount; $i++) {
                $col = $columns[$i]
                "<th onclick='sortTable($i)' style='cursor:pointer;user-select:none;'>$(Encode-Html $col) <span class='sort-indicator' data-col='$i'></span></th>"
            }
            $headerHtml = $headerParts -join ''
            
            # Build filter row
            $filterParts = for ($i = 0; $i -lt $colCount; $i++) {
                "<th><input type='text' class='form-control form-control-sm col-filter' data-col='$i' placeholder='Filter...' onkeyup='applyFilters()'></th>"
            }
            $filterHtml = $filterParts -join ''
            
            # Build data rows - foreach is faster than ForEach-Object
            $rowParts = foreach ($row in $allObjects) {
                $cellParts = foreach ($col in $columns) {
                    "<td>$(Format-TableValue $row.$col)</td>"
                }
                "<tr>$($cellParts -join '')</tr>"
            }
            $rowsHtml = $rowParts -join "`n"
            
            $bodyContent = @"
<div class="mb-3 d-flex gap-2 align-items-center flex-wrap">
    <input type="text" id="searchBox" class="form-control" style="max-width:300px;" placeholder="Global search..." onkeyup="applyFilters()">
    <button class="btn btn-sm btn-outline-secondary" onclick="clearFilters()">Clear Filters</button>
    <span class="text-muted small">Page:</span>
    <nav><ul class="pagination pagination-sm mb-0" id="pagination"></ul></nav>
    <span class="text-muted small" id="pageInfo"></span>
</div>
<div class="table-responsive">
    <table class="table table-striped table-hover" id="dataTable">
        <thead class="table-dark">
            <tr>$headerHtml</tr>
            <tr class="table-secondary">$filterHtml</tr>
        </thead>
        <tbody>$rowsHtml</tbody>
    </table>
</div>
<script>
$tableViewJs
</script>
"@
        }
        else {
            # Card View - collect filterable properties and their unique values
            $filterableProps = @{}
            $firstObj = $allObjects[0]
            foreach ($prop in $firstObj.PSObject.Properties) {
                $val = $prop.Value
                $propName = $prop.Name
                # Only include simple scalar types (not arrays, DateTime, GUIDs, *Count, or GUID-named props) for dropdown filters
                # Inline type check for speed
                if ($null -ne $val -and ($val.PSTypeNames[0] -match $rxSimpleType) -and $propName -ne $TitleProperty -and $val -isnot [DateTime] -and $val -isnot [Guid] -and $propName -notmatch 'Count$' -and $propName -notmatch '^id$|Id$') {
                    $filterableProps[$propName] = @{}
                }
            }
            
            # Collect unique values for each filterable property - cache Keys to avoid repeated enumeration
            $propNamesToCheck = @($filterableProps.Keys)
            foreach ($obj in $allObjects) {
                foreach ($propName in $propNamesToCheck) {
                    $val = $obj.$propName
                    if ($null -ne $val) {
                        $filterableProps[$propName]["$val"] = $true
                    }
                }
            }
            
            # Build dropdown filters HTML (only for props with <= 20 unique values)
            $dropdownFilterParts = @()
            $filterablePropNames = @()
            foreach ($propName in ($filterableProps.Keys | Sort-Object)) {
                $uniqueValues = @($filterableProps[$propName].Keys | Sort-Object)
                if ($uniqueValues.Count -ge 2 -and $uniqueValues.Count -le 20) {
                    $filterablePropNames += $propName
                    # Use property name directly - HTML lowercases data-* attributes automatically
                    $optionParts = foreach ($uv in $uniqueValues) { "<option value='$(Encode-Html $uv)'>$(Encode-Html $uv)</option>" }
                    $optionsHtml = $optionParts -join ''
                    $dropdownFilterParts += "<select class='form-select form-select-sm prop-filter' data-prop='$propName' onchange='applyAllFilters()' style='width:auto;min-width:100px;'><option value=''>$propName</option>$optionsHtml</select>"
                }
            }
            $dropdownFiltersHtml = $dropdownFilterParts -join "`n"
            
            # Pre-calculate title property candidates
            $titleCandidates = @($TitleProperty, 'name', 'id', 'objectId', 'appId')
            
            # Build cards with data attributes for filtering - use foreach for speed
            $cardParts = foreach ($obj in $allObjects) {
                # Determine title
                $usedTitleProp = $null
                $title = "Item"
                foreach ($tc in $titleCandidates) {
                    $tcVal = $obj.$tc
                    if ($tcVal) { 
                        $title = Encode-Html "$tcVal"
                        $usedTitleProp = $tc
                        break 
                    }
                }
                
                # Build data attributes for filterable properties
                # HTML automatically lowercases data-* attribute names
                $attrParts = foreach ($fpn in $filterablePropNames) {
                    $val = $obj.$fpn
                    if ($null -ne $val) {
                        "data-$fpn=`"$(Encode-Html "$val")`""
                    }
                }
                $dataAttrs = $attrParts -join ' '
                
                # Categorize properties - inline type checks
                $simpleProps = @()
                $complexProps = @()
                foreach ($prop in $obj.PSObject.Properties) {
                    $pName = $prop.Name
                    $val = $prop.Value
                    if ($pName -eq $usedTitleProp -or $pName -match $rxOData -or $null -eq $val) { continue }
                    
                    $typeName = $val.PSTypeNames[0]
                    $isValSimple = $typeName -match $rxSimpleType
                    $isCollection = ($typeName -match $rxCollection) -or ($null -ne $val.Count -and $val.Count -gt 0 -and $typeName -notmatch 'String')
                    
                    $isSimple = $isValSimple -or ($isCollection -and $val.Count -gt 0 -and ($val[0].PSTypeNames[0] -match $rxSimpleType))
                    
                    if ($isSimple) { $simpleProps += $prop }
                    else { $complexProps += $prop }
                }
                
                # Build simple properties section
                $simpleSection = ""
                if ($simpleProps.Count -gt 0) {
                    $badgeParts = foreach ($sp in $simpleProps) {
                        "<span class='me-3'><strong class='text-muted small'>$($sp.Name):</strong> $(Format-BadgeValue $sp.Value)</span>"
                    }
                    $simpleSection = "<div class='mb-3 pb-2 border-bottom'>$($badgeParts -join '')</div>"
                }
                
                # Build complex properties section
                $complexSection = switch ($complexProps.Count) {
                    0 { "" }
                    1 { 
                        $cp = $complexProps[0]
                        "<div class='p-2 bg-light rounded'><h6 class='text-primary border-bottom pb-1'>$($cp.Name)</h6><div class='mt-2'>$(Format-BadgeValue $cp.Value)</div></div>"
                    }
                    default {
                        $secParts = foreach ($cp in $complexProps) {
                            "<div class='col'><div class='p-2 bg-light rounded h-100'><h6 class='text-primary border-bottom pb-1'>$($cp.Name)</h6><div class='mt-2'>$(Format-BadgeValue $cp.Value)</div></div></div>"
                        }
                        "<div class='row row-cols-1 row-cols-md-2 row-cols-lg-3 g-3'>$($secParts -join "`n")</div>"
                    }
                }
                
                "<div class='card mb-3' $dataAttrs><div class='card-header bg-primary text-white'><h5 class='mb-0'>$title</h5></div><div class='card-body'>$simpleSection$complexSection</div></div>"
            }
            $cardsHtml = $cardParts -join "`n"
            
            $bodyContent = @"
<div class="mb-3 d-flex gap-2 align-items-center flex-wrap">
    <input type="text" id="searchBox" class="form-control" style="max-width:250px;" placeholder="Search..." onkeyup="filterCards()">
    $dropdownFiltersHtml
    <button class="btn btn-sm btn-outline-secondary" onclick="clearFilters()">Clear</button>
    <span class="text-muted small ms-2">Page:</span>
    <nav><ul class="pagination pagination-sm mb-0" id="pagination"></ul></nav>
    <span class="text-muted small" id="pageInfo"></span>
</div>
<div id="items">$cardsHtml</div>
<script>
$cardViewJs
</script>
"@
        }

        #endregion

        #region Generate HTML
        
        $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>$escapedTitle</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        .bg-info { --bs-bg-opacity: .15; }
        .badge { font-weight: normal; white-space: normal; text-align: left; }
        .prop-filter { font-size: 0.875rem; }
        .card-header h5 { font-size: 1rem; margin: 0; }
        .card-mini-table { font-size: 0.8rem; }
    </style>
</head>
<body class="bg-light">
    <div class="container-fluid py-4">
        <h1 class="border-bottom border-primary pb-2 mb-4">$escapedTitle</h1>
        $bodyContent
    </div>
</body>
</html>
"@

        $html | Out-File -FilePath $Path -Encoding UTF8
        Write-Host "Report exported to: $Path" -ForegroundColor Green
        
        if (-not $NoOpen) { Invoke-Item $Path }
        
        #endregion
    }
}