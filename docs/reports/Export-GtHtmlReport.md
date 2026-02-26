---
external help file: PsGraphToolbox-help.xml
Module Name: PsGraphToolbox
online version: https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Export-GtHtmlReport.md
schema: 2.0.0
---

# Export-GtHtmlReport

## SYNOPSIS
Generate a Bootstrap HTML report from any array of objects.

## SYNTAX

```
Export-GtHtmlReport [-InputObject] <Object[]> [[-TitleProperty] <String>] [[-Path] <String>]
 [[-ReportTitle] <String>] [-NoOpen] [[-PageSize] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
\[AI-GENERATED\] This hot mess of PowerShell and JavaScript was generated using Claude Haiku 4.5.
Generates a self-contained HTML report from an array of objects using Bootstrap 5 for styling and javaScript for interactivity.

Auto-detects object structure and renders one of three view modes:
1.
Table View (flat objects)
When all properties are simple types (strings, numbers, dates, booleans).
Rendered as a searchable, sortable table with per-column filters.

2.
Card View - Single Section (one complex property)
When the object has one nested/complex property.
Rendered as cards with a full-width section for the complex property.
Search filters mini-table rows within visible cards.

3.
Card View - Grid Layout (multiple complex properties)
When the object has two or more nested/complex properties.
Rendered as cards with a responsive multi-column grid layout.
Search shows entire card content without filtering rows.

## EXAMPLES

### EXAMPLE 1
```
$users | Export-GtHtmlReport -Path ".\Users.html" -ReportTitle "User Report"
```

Generates a table view report for flat user objects.

### EXAMPLE 2
```
Get-GtConditionalAccessPolicies | Export-GtHtmlReport -TitleProperty displayName
```

Generates a card view report for complex policy objects.

### EXAMPLE 3
```
$roles | Export-GtHtmlReport -PageSize 50 -NoOpen
```

Generates a report with 50 items per page without opening it.

## PARAMETERS

### -InputObject
The objects to render in the report.
Accepts pipeline input.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -TitleProperty
Property name to use as card titles.
Defaults to 'displayName'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: DisplayName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
Output file path.
Defaults to '.\Report.html'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: .\report.html
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReportTitle
Title displayed at the top of the report.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: Object Report
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoOpen
Suppress automatic opening of the report in default browser.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
Number of items per page.
Defaults to 100.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 100
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Export-GtHtmlReport.md](https://github.com/alflokken/PSGraphToolbox/blob/main/docs/reports/Export-GtHtmlReport.md)

