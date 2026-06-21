using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace UISampleSpark.UI.Pages.EmployeeRazor
{
    /// <summary>
    /// Model for editing an existing employee through Razor Pages
    /// </summary>
    public class EditModel : PageModel
    {
        private readonly Core.Models.Data.EmployeeContext _context;

        /// <summary>
        /// Gets the list of gender options for the dropdown
        /// </summary>
        public SelectList Genders { get; private set; }

        /// <summary>
        /// Initializes a new instance of the <see cref="EditModel"/> class
        /// </summary>
        /// <param name="context">Database context for employee data</param>
        public EditModel(Core.Models.Data.EmployeeContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Gets or sets the employee to be edited
        /// </summary>
        [BindProperty]
        public Core.Models.Data.Employee Employee { get; set; } = default!;

        /// <summary>
        /// Handles GET requests to display the edit page
        /// </summary>
        /// <param name="id">The ID of the employee to edit</param>
        /// <returns>The edit page or a not found result</returns>
        public async Task<IActionResult> OnGetAsync(int? id)
        {
            if (id == null || _context.Employees == null)
            {
                return NotFound();
            }

            // Populate the Genders SelectList with the values from the Gender enum
            Genders = new SelectList(Enum.GetValues(typeof(GenderEnum)));

            Core.Models.Data.Employee? employee = await _context.Employees.FirstOrDefaultAsync(m => m.Id == id);
            if (employee == null)
            {
                return NotFound();
            }
            Employee = employee;
            ViewData["DepartmentId"] = new SelectList(_context.Departments, "Id", "Name");
            return Page();
        }

        /// <summary>
        /// Handles POST requests to process the employee update
        /// </summary>
        /// <returns>Redirects to the index page after update or returns the form with validation errors</returns>
        // To protect from over-posting attacks, enable the specific properties you want to bind to.
        // For more details, see https://aka.ms/RazorPagesCRUD.
        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }

            _context.Attach(Employee).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!EmployeeExists(Employee.Id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return RedirectToPage("./Index");
        }

        private bool EmployeeExists(int id)
        {
            return (_context.Employees?.Any(e => e.Id == id)).GetValueOrDefault();
        }
    }
}
