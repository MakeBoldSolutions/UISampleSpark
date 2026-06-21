using Microsoft.AspNetCore.Mvc.RazorPages;
using System;
using System.Linq;

namespace UISampleSpark.UI.Pages.EmployeeRazor
{
    /// <summary>
    /// Model for deleting an employee through Razor Pages
    /// </summary>
    public class DeleteModel : PageModel
    {
        private readonly Core.Models.Data.EmployeeContext _context;

        /// <summary>
        /// Initializes a new instance of the <see cref="DeleteModel"/> class
        /// </summary>
        /// <param name="context">Database context for employee data</param>
        public DeleteModel(Core.Models.Data.EmployeeContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Gets or sets the employee to be deleted
        /// </summary>
        [BindProperty]
        public Core.Models.Data.Employee Employee { get; set; } = default!;

        /// <summary>
        /// Handles GET requests to display the delete confirmation page
        /// </summary>
        /// <param name="id">The ID of the employee to delete</param>
        /// <returns>The delete confirmation page or a not found result</returns>
        public async Task<IActionResult> OnGetAsync(int? id)
        {
            if (id == null || _context.Employees == null)
            {
                return NotFound();
            }

            Core.Models.Data.Employee? employee = await _context.Employees.FirstOrDefaultAsync(m => m.Id == id);

            if (employee == null)
            {
                return NotFound();
            }
            else
            {
                Employee = employee;
            }
            return Page();
        }

        /// <summary>
        /// Handles POST requests to process the employee deletion
        /// </summary>
        /// <param name="id">The ID of the employee to delete</param>
        /// <returns>Redirects to the index page after deletion</returns>
        public async Task<IActionResult> OnPostAsync(int? id)
        {
            if (id == null || _context.Employees == null)
            {
                return NotFound();
            }
            Core.Models.Data.Employee? employee = await _context.Employees.FindAsync(id);

            if (employee != null)
            {
                Employee = employee;
                _context.Employees.Remove(Employee);
                await _context.SaveChangesAsync();
            }

            return RedirectToPage("./Index");
        }
    }
}
