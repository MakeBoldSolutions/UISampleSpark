global using Microsoft.EntityFrameworkCore;
global using Microsoft.Extensions.Logging;
global using Microsoft.Extensions.Logging.Abstractions;
global using Microsoft.VisualStudio.TestTools.UnitTesting;
global using UISampleSpark.Core.Extensions;
global using UISampleSpark.Core.Models;
global using System;
global using System.Collections.Generic;
global using System.ComponentModel.DataAnnotations;
global using System.Linq;
global using System.Reflection;

[assembly: Parallelize(Workers = 0, Scope = ExecutionScope.MethodLevel)]
