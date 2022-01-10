*** Settings ***
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Word.Application
Library           RPA.PDF
Library           OperatingSystem
Library           RPA.RobotLogListener
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

*** Variables ***
${screenshots}    ${CURDIR}${/}screenshots
${pdfs_temp}      ${CURDIR}${/}pdfs_temp
${zip_file}       ${OUTPUT_DIR}${/}pdf_archives.zip

*** Tasks ***
 Order robots from RobotSpareBin Industries Inc
    Create directories
    ${url}=    Get the order csv url
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        # Check for server error    # if statement
        Fill the form    ${row}
        Wait Until Keyword Succeeds    8x    2s    Preview the robot
        Wait Until Keyword Succeeds    8x    2s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}    ${row}[Order number]
        Go to order another robot
    END
    Log Out and close browser
    Create a ZIP file of the receipts

*** Keywords ***
Create directories
    Create Directory    ${screenshots}
    Create Directory    ${pdfs_temp}
    # Deleting old files
    Empty Directory    ${screenshots}
    Empty Directory    ${pdfs_temp}

Open the robot order website
    ${order_url_web}=    Get Secret    order_web_url
    Open Available Browser    ${order_url_web}[address]
    # Open Available Browser    https://robotsparebinindustries.com/#/robot-order    #Comment out 2 lines above to test locally

Close the annoying modal
    Wait Until Page Contains Element    id:order
    Click Button    OK
# Check for server error
#    server_error = True
#    while server_error:
#    if check_for_server_error:
#    reload_page()
#    close_annoying_modal()
#    return check_for_server_error

Get Orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${bot_orders}=    Read table from CSV    orders.csv
    [Return]    ${bot_orders}

Fill the form
    [Arguments]    ${bot_order}
    Select From List By Value    head    ${bot_order}[Head]
    Select Radio Button    body    ${bot_order}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${bot_order}[Legs]
    Input Text    address    ${bot_order}[Address]

Preview the robot
    Click Button    preview
    Wait Until Element Is Visible    robot-preview-image

Submit the order
    Mute Run On Failure    Page Should Contain Element
    Wait Until Element Is Visible    id:order
    Click Button    order
    Wait Until Element Is Visible    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${Order number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${pdfs_temp}${/}${Order number}.pdf

Take a screenshot of the robot
    [Arguments]    ${Order number}
    Wait Until Element Is Visible    robot-preview-image
    Wait Until Element Is Visible    xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Capture Element Screenshot    robot-preview-image    ${screenshots}${/}${Order number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}    ${Order number}
    ${files}=    Create List    ${screenshots}${/}${Order number}.png:x=0,y=0
    Open Pdf    ${pdfs_temp}${/}${Order number}.pdf
    Add Files To Pdf    ${files}    ${pdfs_temp}${/}${Order number}.pdf    ${True}

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    Archive Folder With ZIP    ${pdfs_temp}    ${zip_file}    recursive=True    include=*.pdf

Get the order csv url
    Add text input    url    placeholder=Please enter the orders csv url
    ${result}=    Run dialog
    [Return]    ${result.url}

Log Out and close browser
    Close Browser
