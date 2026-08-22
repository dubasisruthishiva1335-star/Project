import { Body, Controller, Delete, Param, Patch, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../common/storage.service';
import { ConfirmJobListingDto } from './dto/confirm-job-listing.dto';

@ApiTags('admin-job-listings')
@Controller('admin/job-listings')
export class JobListingsAdminController {
  constructor(private prisma: PrismaService, private storage: StorageService) {}

  @Post('confirm')
  async confirm(@Body() dto: ConfirmJobListingDto) {
    return this.prisma.jobListing.create({
      data: {
        type: (dto.type || 'INTERNSHIP') as any,
        title: dto.title || 'New Opportunity',
        company: dto.company || 'Organization',
        description: dto.description || undefined,
        applyUrl: dto.applyUrl || 'https://myvault-project.vercel.app',
        deadline: dto.deadline ? new Date(dto.deadline) : undefined,
        branch: dto.branch || 'All Branches',
        s3Key: dto.s3Key,
        fileUrl: dto.s3Key ? dto.publicUrl || this.storage.publicUrlFor(dto.s3Key) : dto.publicUrl || undefined,
      },
    });
  }

  @Patch(':id')
  async updateJob(@Param('id') id: string, @Body() body: any) {
    return this.prisma.jobListing.update({
      where: { id },
      data: {
        ...(body.title ? { title: body.title } : {}),
        ...(body.company ? { company: body.company } : {}),
        ...(body.applyUrl ? { applyUrl: body.applyUrl } : {}),
        ...(body.branch ? { branch: body.branch } : {}),
        ...(body.type ? { type: body.type } : {}),
      },
    });
  }

  @Delete('all')
  async deleteAllJobs() {
    await this.prisma.jobListing.deleteMany({});
    return { success: true, message: 'All job listings deleted' };
  }

  @Delete(':id')
  async deleteJob(@Param('id') id: string) {
    return this.prisma.jobListing.delete({
      where: { id },
    });
  }
}
