TestScope "PowerScheduledTasks.psm1" {

    # import the script
   Import-Module ".\PowerScheduledTasks.psm1"
    Enable-Mock | iex
    Describing "PowerScheduledTasks" {
        
        Given "PowerScheduledTasks" {
        TestSetup {           
             Mock Get-ScheduledTask { 
                 $objScheduledTaskName = New-Object System.Object
	    	     $objScheduledTaskName | Add-Member -MemberType NoteProperty -Name TaskName -Value "Prueba"
			     $objScheduledTaskName | Add-Member -MemberType NoteProperty -Name TaskStatus -Value "Listo"
			     $objScheduledTaskName | Where-Object { $_.TaskName -match $TaskName }                                           
             } -When {$TaskStatus -eq "Listo"}
              
             Mock Get-ScheduledTask { 
                 $objScheduledTaskName = New-Object System.Object
	    	     $objScheduledTaskName | Add-Member -MemberType NoteProperty -Name TaskName -Value "PruebaDes"
			     $objScheduledTaskName | Add-Member -MemberType NoteProperty -Name TaskStatus -Value "Deshabilitado"

			     $objScheduledTaskName | Where-Object { $_.TaskName -match $TaskName }   
                                                            
             } -When {$TaskStatus -eq "Deshabilitado"}

             Mock Get-ScheduledTask{
                  $obj=new-object System.Collections.ArrayList
                    $objScheduledTaskName = New-Object System.Object
                    $objScheduledTaskName | Add-Member -MemberType NoteProperty -Name TaskName -Value "Tarea1"
                    $objScheduledTaskName | Add-Member -MemberType NoteProperty -Name TaskStatus -Value "Deshabilitado"
                    $obj.Add($objScheduledTaskName)
                    $objScheduledTaskName = New-Object System.Object
                    $objScheduledTaskName | Add-Member -MemberType NoteProperty -Name TaskName -Value "Tarea2"
                    $objScheduledTaskName | Add-Member -MemberType NoteProperty -Name TaskStatus -Value "Deshabilitado"
                    $obj.Add($objScheduledTaskName)
                    $objScheduledTaskName = New-Object System.Object
                    $objScheduledTaskName | Add-Member -MemberType NoteProperty -Name TaskName -Value "Tarea3"
                    $objScheduledTaskName | Add-Member -MemberType NoteProperty -Name TaskStatus -Value "Listo"
                    $obj.Add($objScheduledTaskName)
                    $objScheduledTaskName = New-Object System.Object
                    $objScheduledTaskName | Add-Member -MemberType NoteProperty -Name TaskName -Value "Tarea4"
                    $objScheduledTaskName | Add-Member -MemberType NoteProperty -Name TaskStatus -Value "Ejecut ndose"
                    $obj.Add($objScheduledTaskName)
                    $objScheduledTaskName = New-Object System.Object
                    $objScheduledTaskName | Add-Member -MemberType NoteProperty -Name TaskName -Value "Tarea5"
                    $objScheduledTaskName | Add-Member -MemberType NoteProperty -Name TaskStatus -Value "Listo"
                    $obj.Add($objScheduledTaskName)
                    $objScheduledTaskName = New-Object System.Object
                    $objScheduledTaskName | Add-Member -MemberType NoteProperty -Name TaskName -Value "Tarea6"
                    $objScheduledTaskName | Add-Member -MemberType NoteProperty -Name TaskStatus -Value "Ejecut ndose"
                    $obj.Add($objScheduledTaskName)
                    $obj
                                 
             }
                              
        }             
                                     
            
           It "Get-ScheduledTaskFilterby" {
               $TaskStatus="Listo" 
               $resu= Get-ScheduledTaskFilterby -TaskStatus "Listo"
               $resu.TaskName | should be "Prueba"
            }

            It "Get-ScheduledTaskFilterby" {
               $TaskStatus="Deshabilitado" 
               $resu= Get-ScheduledTaskFilterby -TaskStatus "Deshabilitado"
               $resu.TaskName | should be "PruebaDes"
            }

            It "Get-ScheduledTaskFilterby" {
               $TaskStatus="Deshabilitado" 
               $resu= Get-ScheduledTaskFilterby -TaskStatus "Ejecut ndose"
               $resu.count | should be 2
            }
        }
    }
}


